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

final class ResizerTests: XCTestCase {

    func testLogoWithinFrame() {
        let frame = CGSize(width: 590, height: 410)
        let imageOriginalSize = CGSize(width: 192, height: 140)
        let renderSize = Resizer.fit(imageOriginalSize, into: frame)

        XCTAssertTrue(renderSize.width <= frame.width)
        XCTAssertTrue(renderSize.height <= frame.height)

        XCTAssertTrue(renderSize.width > imageOriginalSize.width)
        XCTAssertTrue(renderSize.height > imageOriginalSize.height)

        XCTAssertEqual(renderSize.ratio, imageOriginalSize.ratio)
    }

}
