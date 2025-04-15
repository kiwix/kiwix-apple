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

#if os(macOS)
import Foundation
import WebKit

@MainActor
final class ContentSearchViewModel: NSObject, ObservableObject {

    @Published var contentSearchText: String = "" {
        didSet {
            Task { [self] in await self.findNext() }
        }
    }

    /// see: https://developer.apple.com/documentation/webkit/wkwebview/3650493-find
    private var findInWebPage: (String, WKFindConfiguration) async throws -> WKFindResult

    init(findInWebPage: @escaping (String, WKFindConfiguration) async throws -> WKFindResult) {
        self.findInWebPage = findInWebPage
    }

    func findNext() async {
        let config = WKFindConfiguration()
        config.backwards = false
        config.wraps = true
        _ = try? await findInWebPage(contentSearchText, config)
    }

    func findPrevious() async {
        let config = WKFindConfiguration()
        config.backwards = true
        config.wraps = true
        _ = try? await findInWebPage(contentSearchText, config)
    }

    func reset() {
        Task { @MainActor in // intentionally publishing on the next run loop
            contentSearchText = ""
        }
    }
}
#endif
