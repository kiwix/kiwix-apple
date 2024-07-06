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
import WebKit

extension WKNavigationAction {

    /// Checks if the navigation action was a web redirect,
    /// and returns the sourceURL if so
    var redirectedURLFrom: URL? {
        guard let targetURL = request.url,
              sourceFrame != nil, // !important an API error in WebKit, this can actually be nil
              let sourceURL = sourceFrame.request.url else { return nil }
        let targetRoot = targetURL.absoluteString.split(separator: "#").first.map { String($0) }
        guard targetRoot == sourceURL.absoluteString else { return nil }
        return sourceURL
    }
}
