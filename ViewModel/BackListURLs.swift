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

import Foundation

enum BackListURLs {
    static func filteredCanGoBack(backURLs: [URL], current: URL, skipList: [URL: URL]) -> Bool {
        guard !backURLs.isEmpty else {
            return false
        }
        guard !skipList.isEmpty else {
            return true // since the backURLs are not empty at this point
        }
        var previousURL: URL?
        // reverse the order, and go through one by one, to see what should be skipped
        let reversed = Array<URL>((backURLs + [current]).reversed())
        let filteredURLs = reversed.compactMap { url -> URL? in
            if let previous = previousURL,
               skipList[previous] == url {
                previousURL = url
                debugPrint("BackListURLs:: skipping: \(url)")
                return nil
            }
            previousURL = url
            return url
        }
        return filteredURLs.count > 1 // since the list is including the current:URL as well
    }
}
