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

#if os(iOS)
import SwiftUI
import WebKit

struct ContentSearchButton: View {

    @ObservedObject var browser: BrowserViewModel

    var body: some View {
        Button(LocalString.common_search,
               systemImage: "text.magnifyingglass",
               action: { [weak browser] in
            browser?.webView2?.isFindInteractionEnabled = true
            browser?.webView2?.findInteraction?.presentFindNavigator(showingReplace: false)
        }
        ).disabled(browser.url == nil)
    }
}
#endif
