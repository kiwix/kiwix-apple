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
@testable import Kiwix
import Testing

struct GeolocationTests {

    @Test func validFields() async throws {
        let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
        let cllocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 47.6, longitude: -122.3),
            altitude: 80,
            horizontalAccuracy: 5,
            verticalAccuracy: 3,
            course: 90,
            speed: 1.2,
            timestamp: timestamp
        )
        let location = Geolocation(cllocation)
        #expect(location.latitude == 47.6)
        #expect(location.longitude == -122.3)
        #expect(location.vertical?.altitude == 80)
        #expect(location.horizontalAccuracy == 5)
        #expect(location.vertical?.accuracy == 3)
        #expect(location.course == 90)
        #expect(location.speed == 1.2)
        #expect(location.timestamp == timestamp)
    }

}
