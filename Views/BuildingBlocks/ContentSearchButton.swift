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
    @FocusedValue(\.isBrowserURLSet) var isBrowserURLSet
    let findInteraction: () -> Void
    
    init(browser: BrowserViewModel) {
        findInteraction = { [weak browser] in
            browser?.webView.isFindInteractionEnabled = true
            browser?.webView.findInteraction?.presentFindNavigator(showingReplace: false)
        }
    }

    var body: some View {
        Button(LocalString.common_search,
               systemImage: "text.magnifyingglass",
               action: {
            findInteraction()
        }
        ).disabled(isBrowserURLSet != true)
    }
}
#endif
