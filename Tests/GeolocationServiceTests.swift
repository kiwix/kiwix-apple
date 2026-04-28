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
import XCTest
@testable import Kiwix

final class GeolocationServiceTests: XCTestCase {

    func testSnapshotCopiesValidFields() {
        let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 47.6, longitude: -122.3),
            altitude: 80,
            horizontalAccuracy: 5,
            verticalAccuracy: 3,
            course: 90,
            speed: 1.2,
            timestamp: timestamp
        )
        let snapshot = LocationSnapshot(location)
        XCTAssertEqual(snapshot.latitude, 47.6, accuracy: 0.0001)
        XCTAssertEqual(snapshot.longitude, -122.3, accuracy: 0.0001)
        XCTAssertEqual(snapshot.horizontalAccuracy, 5)
        XCTAssertEqual(snapshot.altitude, 80)
        XCTAssertEqual(snapshot.verticalAccuracy, 3)
        XCTAssertEqual(snapshot.course, 90)
        XCTAssertEqual(snapshot.speed, 1.2)
        XCTAssertEqual(snapshot.timestamp, timestamp)
    }

    func testSnapshotDropsInvalidFields() {
        // CoreLocation marks unavailable fields with negative sentinel values.
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            altitude: 0,
            horizontalAccuracy: 10,
            verticalAccuracy: -1,
            course: -1,
            speed: -1,
            timestamp: Date()
        )
        let snapshot = LocationSnapshot(location)
        XCTAssertNil(snapshot.altitude)
        XCTAssertNil(snapshot.verticalAccuracy)
        XCTAssertNil(snapshot.course)
        XCTAssertNil(snapshot.speed)
    }

    func testGeolocationErrorRawValuesMatchHTML5Spec() {
        // The PositionError code constants in the W3C Geolocation API are
        // stable; the JS shim relies on these exact values.
        XCTAssertEqual(GeolocationError.permissionDenied.rawValue, 1)
        XCTAssertEqual(GeolocationError.positionUnavailable.rawValue, 2)
        XCTAssertEqual(GeolocationError.timeout.rawValue, 3)
    }

    // MARK: - Wire-format payload (the contract with every map ZIM)

    func testSnapshotPayloadIncludesAllFieldsWhenPresent() throws {
        let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
        let snapshot = LocationSnapshot(CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 47.6, longitude: -122.3),
            altitude: 80,
            horizontalAccuracy: 5,
            verticalAccuracy: 3,
            course: 90,
            speed: 1.2,
            timestamp: timestamp
        ))
        let payload = snapshot.payload
        let coords = try XCTUnwrap(payload["coords"] as? [String: Any])
        XCTAssertEqual(coords["latitude"] as? Double, 47.6)
        XCTAssertEqual(coords["longitude"] as? Double, -122.3)
        XCTAssertEqual(coords["accuracy"] as? Double, 5)
        XCTAssertEqual(coords["altitude"] as? Double, 80)
        XCTAssertEqual(coords["altitudeAccuracy"] as? Double, 3)
        XCTAssertEqual(coords["heading"] as? Double, 90)
        XCTAssertEqual(coords["speed"] as? Double, 1.2)
        // W3C says timestamp is in milliseconds since epoch.
        XCTAssertEqual(payload["timestamp"] as? Double, timestamp.timeIntervalSince1970 * 1000)
    }

    func testSnapshotPayloadOmitsAbsentOptionalFields() {
        // When CLLocation marks fields as unavailable (negative sentinels),
        // the payload must omit them rather than emit null — that's the shape
        // a real navigator.geolocation produces.
        let snapshot = LocationSnapshot(CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            altitude: 0,
            horizontalAccuracy: 10,
            verticalAccuracy: -1,
            course: -1,
            speed: -1,
            timestamp: Date()
        ))
        let coords = snapshot.payload["coords"] as? [String: Any]
        XCTAssertNotNil(coords)
        XCTAssertNil(coords?["altitude"])
        XCTAssertNil(coords?["altitudeAccuracy"])
        XCTAssertNil(coords?["heading"])
        XCTAssertNil(coords?["speed"])
        // Required fields are always present.
        XCTAssertNotNil(coords?["latitude"])
        XCTAssertNotNil(coords?["longitude"])
        XCTAssertNotNil(coords?["accuracy"])
    }

    func testGeolocationErrorPayloadShape() {
        let payload = GeolocationError.permissionDenied.payload
        let error = payload["error"] as? [String: Any]
        XCTAssertEqual(error?["code"] as? Int, 1)
        XCTAssertEqual(error?["message"] as? String, GeolocationError.permissionDenied.message)
    }

    func testGeolocationErrorPayloadAcceptsCustomCodeAndMessage() {
        // Used by the generic-catch path in BrowserViewModel for non-GeolocationError throws.
        let payload = GeolocationError.payload(code: 99, message: "underlying CL error")
        let error = payload["error"] as? [String: Any]
        XCTAssertEqual(error?["code"] as? Int, 99)
        XCTAssertEqual(error?["message"] as? String, "underlying CL error")
    }
}
