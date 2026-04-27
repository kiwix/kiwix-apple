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

    var message: String {
        switch self {
        case .permissionDenied: return "User denied geolocation permission."
        case .positionUnavailable: return "Location is unavailable."
        case .timeout: return "Location request timed out."
        }
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
    /// on first use. Does not disturb any active continuous watches.
    func requestLocation(highAccuracy: Bool) async throws -> LocationSnapshot {
        try await ensureAuthorized()
        return try await withCheckedThrowingContinuation { continuation in
            oneShotContinuations.append(continuation)
            if !isUpdatingContinuously {
                // Only adjust accuracy when no watches are running, so one-shot
                // requests don't downgrade a high-accuracy watch.
                manager.desiredAccuracy = highAccuracy
                    ? kCLLocationAccuracyBest
                    : kCLLocationAccuracyHundredMeters
            } else if highAccuracy {
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
        let waiting = authorizationContinuations
        authorizationContinuations.removeAll()
        for continuation in waiting {
            continuation.resume(returning: status)
        }
        // If authorization is revoked while watching, notify watchers and stop.
        if status == .denied || status == .restricted {
            let active = watchers
            for handler in active.values {
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
        for handler in watchers.values {
            handler(.success(snapshot))
        }
    }

    fileprivate func didFail(code: Int, message: String) {
        let waiting = oneShotContinuations
        oneShotContinuations.removeAll()
        let error = NSError(
            domain: "org.kiwix.geolocation",
            code: code,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
        for continuation in waiting {
            continuation.resume(throwing: error)
        }
        // Forward errors to active watchers but keep the watch alive; the
        // web page can call clearWatch if it wants to stop.
        let geoError: GeolocationError = {
            if code == CLError.denied.rawValue { return .permissionDenied }
            return .positionUnavailable
        }()
        for handler in watchers.values {
            handler(.failure(geoError))
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
