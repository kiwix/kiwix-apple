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

protocol JSRespondable {
    var jsResponse: [String: Any] { get }
}

/// Matching the DOM equivalent from:
/// https://www.w3.org/TR/geolocation/#dom-geolocationpositionerror
enum GeolocationPositionError: Int, Error, JSRespondable {
    case permissionDenied = 1
    case positionUnavailable = 2
    case timeout = 3

    var localizedDescription: String {
        switch self {
        case .permissionDenied: return LocalString.geolocation_error_permission_denied
        case .positionUnavailable: return LocalString.geolocation_error_position_unavailable
        case .timeout: return LocalString.geolocation_error_timeout
        }
    }

    var jsResponse: [String: Any] {
        ["error": ["code": rawValue, "message": localizedDescription]]
    }
}

/// The incoming request from JS
struct LocationRequest: Sendable {
    let type: RequestMethod
    let highAccuracy: Bool
    
    enum RequestMethod: String {
        case getCurrentPosition
        case watchPosition
        case clearWatch
    }
    
    init?(jsRequest payload: [String: Any]) {
        guard let payloadType = payload["type"] as? String,
              let requestMethod = RequestMethod(rawValue: payloadType) else { return nil }
        type = requestMethod
        highAccuracy = (payload["highAccuracy"] as? NSNumber)?.boolValue ?? false
    }
}

/// Sendable snapshot of a CLLocation, safe to pass across isolation domains.
struct Geolocation: Sendable, JSRespondable {
    struct Vertical {
        let altitude: Double
        let accuracy: Double
    }
    let latitude: Double
    let longitude: Double
    let horizontalAccuracy: Double
    let vertical: Vertical?
    let course: Double?
    let speed: Double?
    let timestamp: Date

    init(_ location: CLLocation) {
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
        horizontalAccuracy = location.horizontalAccuracy
        if location.verticalAccuracy >= 0 {
            vertical = Vertical(altitude: location.altitude, accuracy: location.verticalAccuracy)
        } else {
            vertical = nil
        }
        course = location.course >= 0 ? location.course : nil
        speed = location.speed >= 0 ? location.speed : nil
        timestamp = location.timestamp
    }

    var jsResponse: [String: Any] {
        var coords: [String: Any] = [
            "latitude": latitude,
            "longitude": longitude,
            "accuracy": horizontalAccuracy
        ]
        if let vertical {
            coords["altitude"] = vertical.altitude
            coords["altitudeAccuracy"] = vertical.accuracy
        }
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
final class GeolocationService: NSObject, @MainActor CLLocationManagerDelegate {

    typealias WatchHandler = @MainActor (Result<Geolocation, GeolocationPositionError>) -> Void

    private let manager: CLLocationManager

    private var authorizationContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?
    private var oneShotContinuation: CheckedContinuation<Geolocation, Error>?
    private var watcher: WatchHandler?
    private var watcherAccuracy: Bool = false
    private var isUpdatingContinuously = false

    override init() {
        manager = CLLocationManager()
        super.init()
        manager.delegate = self
    }

    // MARK: - Authorization
    func requestAuthorization() async -> CLAuthorizationStatus {
        let status = manager.authorizationStatus
        guard status == .notDetermined else { return status }
        return await withCheckedContinuation { continuation in
            let isFirstWaiter = authorizationContinuation == nil
            authorizationContinuation = continuation
            guard isFirstWaiter else { return }
            manager.requestWhenInUseAuthorization()
        }
    }

    private func ensureAuthorized() async throws {
        let status = await requestAuthorization()
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            return
        case .denied, .restricted, .notDetermined:
            throw GeolocationPositionError.permissionDenied
        @unknown default:
            throw GeolocationPositionError.positionUnavailable
        }
    }

    func requestLocation(highAccuracy: Bool) async throws -> Geolocation {
        try await ensureAuthorized()
        return try await withCheckedThrowingContinuation { continuation in
            oneShotContinuation = continuation
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
    func startWatching(highAccuracy: Bool, onUpdate: @escaping WatchHandler) async {
        do {
            try await ensureAuthorized()
        } catch let error as GeolocationPositionError {
            onUpdate(.failure(error))
            return
        } catch {
            onUpdate(.failure(.positionUnavailable))
            return
        }
        watcher = onUpdate
        watcherAccuracy = highAccuracy
        applyAccuracyForWatchers()
        if !isUpdatingContinuously {
            isUpdatingContinuously = true
            manager.startUpdatingLocation()
        }
    }
    
    func stopWatching() {
        watcher = nil
        watcherAccuracy = false
        if isUpdatingContinuously {
            isUpdatingContinuously = false
            manager.stopUpdatingLocation()
        }
    }

    private func applyAccuracyForWatchers() {
        manager.desiredAccuracy = watcherAccuracy
            ? kCLLocationAccuracyBest
            : kCLLocationAccuracyHundredMeters
    }

    // MARK: Geolocation delegate
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        guard status != .notDetermined else { return }
        let waitingAuth = authorizationContinuation
        authorizationContinuation = nil
        waitingAuth?.resume(returning: status)
        
        // If authorization is revoked, drain in-flight one-shots and watches —
        // CoreLocation may not fire didFailWithError before the next call, so
        // any awaiting CheckedContinuation would leak.
        if status == .denied || status == .restricted {
            let waitingOneShot = oneShotContinuation
            oneShotContinuation = nil
            waitingOneShot?.resume(throwing: GeolocationPositionError.permissionDenied)
            watcher?(.failure(.permissionDenied))
            stopWatching()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        let snapshot = Geolocation(latest)
        let waiting = oneShotContinuation
        oneShotContinuation = nil
        waiting?.resume(returning: snapshot)
        
        // Snapshot before iterating: handlers may call stopWatching(id:),
        // mutating the dict mid-iteration.
        watcher?(.success(snapshot))
        // A one-shot may have promoted desiredAccuracy above the watch's
        // configured level; restore so the watch doesn't keep burning battery.
        if waiting != nil, isUpdatingContinuously {
            applyAccuracyForWatchers()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let nsError = error as NSError
        let code = nsError.code
        let message = nsError.localizedDescription
        let waiting = oneShotContinuation
        oneShotContinuation = nil

        // Map CLError codes to the W3C PositionError code the JS bridge expects.
        // Unmapped codes fall through as positionUnavailable.
        let geoError: GeolocationPositionError
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
        waiting?.resume(throwing: error)

        // Restore accuracy for any active watch that a one-shot may have promoted.
        if waiting != nil, isUpdatingContinuously {
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
        watcher?(.failure(geoError))
        if code == CLError.denied.rawValue {
            stopWatching()
        }
    }
}
