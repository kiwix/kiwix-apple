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

/// Groups the Geolocation response types we send to JS
protocol JSRespondable {
    var jsResponse: [String: Any] { get }
}

enum GeolocationPositionError: Int, Error, JSRespondable {
    // Matching the DOM equivalent from:
    // https://www.w3.org/TR/geolocation/#dom-geolocationpositionerror
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

struct Geolocation: JSRespondable {
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

/// The incoming Geolocation request from JS
struct LocationRequest {
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

/// Provides geolocation to the WebKit viewer, bridging HTML5 Geolocation API
/// calls from ZIM content (e.g. map ZIMs) to CoreLocation. Supports both
/// one-shot (`getCurrentPosition`) and continuous (`watchPosition`) requests.
@MainActor
final class GeolocationService: NSObject, @MainActor CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var authorizationContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?
    private var oneShotContinuation: CheckedContinuation<Geolocation, Error>?
    private var onLocationUpdate: ((Result<Geolocation, GeolocationPositionError>) -> Void)?
    private var useHighAccuracy: Bool = false
    private var isWatching = false
    private var lastKnownLocation: Geolocation?

    override init() {
        super.init()
        manager.delegate = self
    }

    // MARK: - Authorization
    private func requestAuthorization() async -> CLAuthorizationStatus {
        let status = manager.authorizationStatus
        guard status == .notDetermined else { return status }
        return await withCheckedContinuation { continuation in
            guard authorizationContinuation == nil else { return }
            authorizationContinuation = continuation
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
        if isWatching, let lastKnownLocation {
            return lastKnownLocation
        }
        // check any old continuations of the same type
        guard oneShotContinuation == nil else {
            Log.Geolocation.debug("requesting location again, when the previous one wasn't complete yet")
            throw GeolocationPositionError.timeout
        }
        
        try await ensureAuthorized()
        return try await withCheckedThrowingContinuation { continuation in
            oneShotContinuation = continuation
            if !isWatching {
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
    func startWatching(
        highAccuracy: Bool,
        onUpdate: @escaping @MainActor (Result<Geolocation, GeolocationPositionError>) -> Void
    ) async {
        debugPrint("\(#function)")
        do {
            try await ensureAuthorized()
        } catch let error as GeolocationPositionError {
            onUpdate(.failure(error))
            return
        } catch {
            onUpdate(.failure(.positionUnavailable))
            return
        }
        onLocationUpdate = onUpdate
        useHighAccuracy = highAccuracy
        applyAccuracyForWatchers()
        if !isWatching {
            isWatching = true
            manager.startUpdatingLocation()
        }
    }
    
    func stopAll() {
        oneShotContinuation?.resume(throwing: GeolocationPositionError.timeout)
        oneShotContinuation = nil
        stopWatching()
    }
    
    func stopWatching() {
        onLocationUpdate = nil
        useHighAccuracy = false
        if isWatching {
            isWatching = false
            manager.stopUpdatingLocation()
        }
    }

    private func applyAccuracyForWatchers() {
        // Restore accuracy for any active watch that a one-shot may have promoted.
        manager.desiredAccuracy = useHighAccuracy
            ? kCLLocationAccuracyBest
            : kCLLocationAccuracyHundredMeters
    }

    // MARK: CLLocationManagerDelegate
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        guard status != .notDetermined else { return }
        let waitingAuth = authorizationContinuation
        authorizationContinuation = nil
        waitingAuth?.resume(returning: status)
        
        if status == .denied || status == .restricted {
            oneShotContinuation?.resume(throwing: GeolocationPositionError.permissionDenied)
            oneShotContinuation = nil
            onLocationUpdate?(.failure(.permissionDenied))
            stopWatching()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        let snapshot = Geolocation(latest)
        // store it for later
        lastKnownLocation = snapshot
        let waiting = oneShotContinuation
        oneShotContinuation = nil
        waiting?.resume(returning: snapshot)
        
        onLocationUpdate?(.success(snapshot))
        // A one-shot may have promoted desiredAccuracy above the watch's
        // configured level; restore so the watch doesn't keep burning battery.
        if waiting != nil, isWatching {
            applyAccuracyForWatchers()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let oneShot = oneShotContinuation
        oneShotContinuation = nil
        if oneShot != nil, isWatching {
            applyAccuracyForWatchers()
        }
        
        let geolocationError: GeolocationPositionError
        switch (error as NSError).code {
        case CLError.denied.rawValue:
            geolocationError = .permissionDenied
            oneShot?.resume(throwing: geolocationError)
            onLocationUpdate?(.failure(geolocationError))
            stopWatching()
        case CLError.locationUnknown.rawValue:
            geolocationError = .positionUnavailable
            oneShot?.resume(throwing: geolocationError)
            // don't inform watch about it
            // don't stop watching
        default:
            geolocationError = .positionUnavailable
            oneShot?.resume(throwing: geolocationError)
            onLocationUpdate?(.failure(geolocationError))
            // don't stop watching
        }
    }
}
