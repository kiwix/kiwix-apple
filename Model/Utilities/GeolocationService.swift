// This file is part of Kiwix for iOS & macOS.
//
// Kiwix is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// any later version.
//
// Kiwix is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Kiwix; If not, see https://www.gnu.org/licenses/.

import CoreLocation
import Foundation

/// Errors matching the HTML5 Geolocation API `PositionError` codes.
enum GeolocationError: Int, Error {
    case permissionDenied = 1
    case positionUnavailable = 2
    case timeout = 3

    /// Surfaced to ZIM pages as `PositionError.message`, so it follows the
    /// app's localization pipeline like other user-visible strings.
    var message: String {
        switch self {
        case .permissionDenied: return LocalString.geolocation_error_permission_denied
        case .positionUnavailable: return LocalString.geolocation_error_position_unavailable
        case .timeout: return LocalString.geolocation_error_timeout
        }
    }
}

/// W3C-Geolocation `PositionError` payload shape used by the JS bridge.
extension GeolocationError {
    static func payload(code: Int, message: String) -> [String: Any] {
        ["error": ["code": code, "message": message]]
    }

    var payload: [String: Any] {
        Self.payload(code: rawValue, message: message)
    }
}

/// Sendable snapshot of a CLLocation, safe to pass across isolation domains.
struct LocationSnapshot: Sendable {
    let latitude: Double
    let longitude: Double
    let horizontalAccuracy: Double
    let altitude: Double?
    let verticalAccuracy: Double?
    let course: Double?
    let speed: Double?
    let timestamp: Date

    init(_ location: CLLocation) {
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
        horizontalAccuracy = location.horizontalAccuracy
        if location.verticalAccuracy >= 0 {
            altitude = location.altitude
            verticalAccuracy = location.verticalAccuracy
        } else {
            altitude = nil
            verticalAccuracy = nil
        }
        course = location.course >= 0 ? location.course : nil
        speed = location.speed >= 0 ? location.speed : nil
        timestamp = location.timestamp
    }

    /// W3C-Geolocation `Position` payload shape used by the JS bridge. Optional
    /// fields are omitted (rather than emitted as null) so the JS side sees the
    /// same shape it would from a real `navigator.geolocation` implementation.
    var payload: [String: Any] {
        var coords: [String: Any] = [
            "latitude": latitude,
            "longitude": longitude,
            "accuracy": horizontalAccuracy
        ]
        if let altitude { coords["altitude"] = altitude }
        if let verticalAccuracy { coords["altitudeAccuracy"] = verticalAccuracy }
        if let course { coords["heading"] = course }
        if let speed { coords["speed"] = speed }
        return [
            "coords": coords,
            "timestamp": timestamp.timeIntervalSince1970 * 1000
        ]
    }
}

/// Provides geolocation to the WebKit viewer, bridging HTML5 Geolocation API
/// calls from ZIM content (e.g. map ZIMs) to CoreLocation. Supports both
/// one-shot (`getCurrentPosition`) and continuous (`watchPosition`) requests.
///
/// CoreLocation authorization is requested lazily on the first location request,
/// so users of ZIMs that never touch `navigator.geolocation` are never prompted.
@MainActor
final class GeolocationService: NSObject {

    typealias WatchHandler = @MainActor (Result<LocationSnapshot, GeolocationError>) -> Void

    private let manager: CLLocationManager
    private let delegateShim = GeolocationDelegateShim()

    private var authorizationContinuations: [CheckedContinuation<CLAuthorizationStatus, Never>] = []
    private var oneShotContinuations: [CheckedContinuation<LocationSnapshot, Error>] = []
    private var watchers: [Int: WatchHandler] = [:]
    private var watcherAccuracies: [Int: Bool] = [:]
    private var isUpdatingContinuously = false

    override init() {
        manager = CLLocationManager()
        super.init()
        delegateShim.owner = self
        manager.delegate = delegateShim
    }

    // MARK: - Authorization

    /// Returns the current CoreLocation authorization status, prompting the
    /// user if it has not yet been decided. Concurrent callers share a single
    /// system prompt — the second-and-subsequent calls just join the wait.
    func requestAuthorization() async -> CLAuthorizationStatus {
        let status = manager.authorizationStatus
        guard status == .notDetermined else { return status }
        return await withCheckedContinuation { continuation in
            let isFirstWaiter = authorizationContinuations.isEmpty
            authorizationContinuations.append(continuation)
            guard isFirstWaiter else { return }
            // When-in-use matches the user-initiated, web-driven nature of
            // navigator.geolocation on both platforms; Always would be
            // overreach for a web-content permission prompt.
            manager.requestWhenInUseAuthorization()
        }
    }

    private func ensureAuthorized() async throws {
        let status = await requestAuthorization()
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            return
        case .denied, .restricted, .notDetermined:
            throw GeolocationError.permissionDenied
        @unknown default:
            throw GeolocationError.positionUnavailable
        }
    }

    // MARK: - One-shot

    /// Requests a one-shot location reading. Prompts the user for authorization
    /// on first use. A high-accuracy one-shot may temporarily promote (but
    /// never demote) the desired accuracy of an in-flight watch; the watch's
    /// configured accuracy is restored once the one-shot resolves.
    func requestLocation(highAccuracy: Bool) async throws -> LocationSnapshot {
        try await ensureAuthorized()
        return try await withCheckedThrowingContinuation { continuation in
            oneShotContinuations.append(continuation)
            if !isUpdatingContinuously {
                manager.desiredAccuracy = highAccuracy
                    ? kCLLocationAccuracyBest
                    : kCLLocationAccuracyHundredMeters
            } else if highAccuracy {
                // Promote only — never downgrade an active high-accuracy watch.
                manager.desiredAccuracy = kCLLocationAccuracyBest
            }
            manager.requestLocation()
        }
    }

    // MARK: - Continuous watch

    /// Starts a continuous watch with the given id. `onUpdate` is invoked on
    /// the main actor for every location update, and for errors (which do not
    /// terminate the watch — stop with `stopWatching(id:)`).
    func startWatching(id: Int, highAccuracy: Bool, onUpdate: @escaping WatchHandler) async {
        do {
            try await ensureAuthorized()
        } catch let error as GeolocationError {
            onUpdate(.failure(error))
            return
        } catch {
            onUpdate(.failure(.positionUnavailable))
            return
        }
        watchers[id] = onUpdate
        watcherAccuracies[id] = highAccuracy
        applyAccuracyForWatchers()
        if !isUpdatingContinuously {
            isUpdatingContinuously = true
            manager.startUpdatingLocation()
        }
    }

    /// Stops a specific watch. If no watches remain, CoreLocation updates stop.
    func stopWatching(id: Int) {
        watchers.removeValue(forKey: id)
        watcherAccuracies.removeValue(forKey: id)
        if watchers.isEmpty {
            if isUpdatingContinuously {
                isUpdatingContinuously = false
                manager.stopUpdatingLocation()
            }
        } else {
            applyAccuracyForWatchers()
        }
    }

    /// Stops all watches (e.g. when the tab is torn down).
    func stopAllWatches() {
        watchers.removeAll()
        watcherAccuracies.removeAll()
        if isUpdatingContinuously {
            isUpdatingContinuously = false
            manager.stopUpdatingLocation()
        }
    }

    private func applyAccuracyForWatchers() {
        let wantsHigh = watcherAccuracies.values.contains(true)
        manager.desiredAccuracy = wantsHigh
            ? kCLLocationAccuracyBest
            : kCLLocationAccuracyHundredMeters
    }

    // MARK: - Delegate callbacks (invoked from GeolocationDelegateShim)

    fileprivate func didChangeAuthorization(status: CLAuthorizationStatus) {
        guard status != .notDetermined else { return }
        let waitingAuth = authorizationContinuations
        authorizationContinuations.removeAll()
        for continuation in waitingAuth {
            continuation.resume(returning: status)
        }
        // If authorization is revoked, drain in-flight one-shots and watches —
        // CoreLocation may not fire didFailWithError before the next call, so
        // any awaiting CheckedContinuation would leak.
        if status == .denied || status == .restricted {
            let waitingOneShots = oneShotContinuations
            oneShotContinuations.removeAll()
            for continuation in waitingOneShots {
                continuation.resume(throwing: GeolocationError.permissionDenied)
            }
            for handler in Array(watchers.values) {
                handler(.failure(.permissionDenied))
            }
            stopAllWatches()
        }
    }

    fileprivate func didUpdate(snapshot: LocationSnapshot) {
        let waiting = oneShotContinuations
        oneShotContinuations.removeAll()
        for continuation in waiting {
            continuation.resume(returning: snapshot)
        }
        // Snapshot before iterating: handlers may call stopWatching(id:),
        // mutating the dict mid-iteration.
        for handler in Array(watchers.values) {
            handler(.success(snapshot))
        }
        // A one-shot may have promoted desiredAccuracy above the watch's
        // configured level; restore so the watch doesn't keep burning battery.
        if !waiting.isEmpty, isUpdatingContinuously {
            applyAccuracyForWatchers()
        }
    }

    fileprivate func didFail(code: Int, message: String) {
        let waiting = oneShotContinuations
        oneShotContinuations.removeAll()

        // Map CLError codes to the W3C PositionError code the JS bridge expects.
        // Unmapped codes fall through as positionUnavailable.
        let geoError: GeolocationError
        switch code {
        case CLError.denied.rawValue:
            geoError = .permissionDenied
        case CLError.locationUnknown.rawValue:
            // Per W3C: locationUnknown is transient — don't fire watch errors.
            // For one-shots we still need to resolve; fall through.
            geoError = .positionUnavailable
        default:
            geoError = .positionUnavailable
        }

        let error = NSError(
            domain: "org.kiwix.geolocation",
            code: code,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
        for continuation in waiting {
            continuation.resume(throwing: error)
        }

        // Restore accuracy for any active watch that a one-shot may have promoted.
        if !waiting.isEmpty, isUpdatingContinuously {
            applyAccuracyForWatchers()
        }

        // Watch error semantics:
        //  - locationUnknown: transient; do not invoke watch error callbacks.
        //  - denied: permanent; notify watchers, then stop CoreLocation so we
        //    don't keep the GPS warm for a permission that won't come back.
        //  - other: notify watchers, leave the watch running so the page can
        //    decide whether to keep waiting or call clearWatch.
        if code == CLError.locationUnknown.rawValue {
            return
        }
        for handler in Array(watchers.values) {
            handler(.failure(geoError))
        }
        if code == CLError.denied.rawValue {
            stopAllWatches()
        }
    }
}

/// Nonisolated shim so CLLocationManager can invoke delegate methods from
/// CoreLocation's internal queue while keeping GeolocationService on MainActor.
private final class GeolocationDelegateShim: NSObject, CLLocationManagerDelegate {
    weak var owner: GeolocationService?

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor [weak owner] in
            owner?.didChangeAuthorization(status: status)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        let snapshot = LocationSnapshot(latest)
        Task { @MainActor [weak owner] in
            owner?.didUpdate(snapshot: snapshot)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let nsError = error as NSError
        let code = nsError.code
        let message = nsError.localizedDescription
        Task { @MainActor [weak owner] in
            owner?.didFail(code: code, message: message)
        }
    }
}
