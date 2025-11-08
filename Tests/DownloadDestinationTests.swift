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

struct DownloadDestinationTests {

    @Test(
        arguments: [
            ("Wiki-Med.ZIM", "Wiki-Med-2.zim"),
            ("ray-charles_mini_2025-11.zim", "ray-charles_mini_2025-11-2.zim")
        ]
    )
    func fileNameIncrements(fileName: String, expected: String) async throws {
        let baseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = baseURL.appending(path: fileName)
        
        let same = DownloadDestination.alternateLocalPathFor(downloadURL: fileURL, count: 0)
        #expect(same.lastPathComponent == fileName)
        let next = DownloadDestination.alternateLocalPathFor(downloadURL: fileURL, count: 1)
        #expect(next.lastPathComponent == expected)
    }

}
