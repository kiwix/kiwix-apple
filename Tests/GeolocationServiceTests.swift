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
        let snapshot = Geolocation(location)
        XCTAssertNil(snapshot.vertical)
        XCTAssertNil(snapshot.course)
        XCTAssertNil(snapshot.speed)
    }

    // MARK: - Wire-format payload (the contract with every map ZIM)

    func testSnapshotPayloadIncludesAllFieldsWhenPresent() throws {
        let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
        let snapshot = Geolocation(CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 47.6, longitude: -122.3),
            altitude: 80,
            horizontalAccuracy: 5,
            verticalAccuracy: 3,
            course: 90,
            speed: 1.2,
            timestamp: timestamp
        ))
        let payload = snapshot.jsResponse
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
        let snapshot = Geolocation(CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            altitude: 0,
            horizontalAccuracy: 10,
            verticalAccuracy: -1,
            course: -1,
            speed: -1,
            timestamp: Date()
        ))
        let coords = snapshot.jsResponse["coords"] as? [String: Any]
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
}
