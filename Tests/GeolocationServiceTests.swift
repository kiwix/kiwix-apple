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
        // The PositionError codes in the W3C Geolocation API are stable; the JS
        // shim relies on these exact values for the PERMISSION_DENIED constant.
        XCTAssertEqual(GeolocationError.permissionDenied.rawValue, 1)
        XCTAssertEqual(GeolocationError.positionUnavailable.rawValue, 2)
        XCTAssertEqual(GeolocationError.timeout.rawValue, 3)
    }
}
