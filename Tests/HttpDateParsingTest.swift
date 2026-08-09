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

import Testing
@testable import Kiwix

struct HttpDateParsingTest {

    private static let nowString = "Mon, 03 Feb 2020 14:55:22 GMT"
    private static let now = Date(timeIntervalSince1970: 1580741722)
    
    @Test
    func dateToString() async throws {
        let date = CookieParserResult.dateFrom(httpValue: Self.nowString)
        #expect(date == Self.now)
    }
}
