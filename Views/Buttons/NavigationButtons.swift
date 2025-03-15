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

import SwiftUI
import Combine
import CoreData

struct NavigationButtons: View {
    @Environment(\.dismissSearch) private var dismissSearch
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    var currentTabId: NSManagedObjectID

    var body: some View {
        goBackButton
        Spacer()
        goForwardButton
    }

    var goBackButton: some View {
        Button {
            browser()?.webView2?.goBack()
            dismissSearch()
        } label: {
            Label(LocalString.common_button_go_back, systemImage: "chevron.left")
        }.disabled(browser()?.canGoBack != true)
    }

    var goForwardButton: some View {
        Button {
            browser()?.webView2?.goForward()
            dismissSearch()
        } label: {
            Label(LocalString.common_button_go_forward, systemImage: "chevron.right")
        }.disabled(browser()?.canGoForward != true)
    }
    
    private func browser() -> BrowserViewModel? {
        BrowserViewModel.getCached(tabID: currentTabId)
    }
}
