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

import XCTest
@testable import Kiwix

final class URLContentPathTests: XCTestCase {

    private let testURLs = [
        URL(string: "kiwix://6E4F3D4A-2F8A-789A-3B88-212219F4FB27/irp.fas.org/doddir/milmed/index.html")!,
        URL(string: "kiwix://861C031F-DAFB-9688-4DB4-8F1199FE2926/mesquartierschinois.wordpress.com/")!
    ]

    func test_no_leading_slash() {
        testURLs.forEach { url in
            XCTAssertFalse(url.contentPath.first == "/")
        }
    }

    func test_preserves_trailing_slash() {
        let url = URL(string: "kiwix://861C031F-DAFB-9688-4DB4-8F1199FE2926/mesquartierschinois.wordpress.com/")!
        XCTAssertEqual(url.contentPath.last, "/")
    }

    func test_value() {
        XCTAssertEqual(testURLs.map { $0.contentPath }, [
            "irp.fas.org/doddir/milmed/index.html",
            "mesquartierschinois.wordpress.com/"
        ])
    }

}
