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

struct NavigationButtons: View {
    @Environment(\.dismissSearch) private var dismissSearch
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var browser: BrowserViewModel

    var body: some View {
        goBackButton
        Spacer()
        goForwardButton
    }

    var goBackButton: some View {
        Button {
            browser.webView.goBack()
            dismissSearch()
        } label: {
            Label(LocalString.common_button_go_back, systemImage: "chevron.left")
        }.disabled(!browser.canGoBack)
    }

    var goForwardButton: some View {
        Button {
            browser.webView.goForward()
            dismissSearch()
        } label: {
            Label(LocalString.common_button_go_forward, systemImage: "chevron.right")
        }.disabled(!browser.canGoForward)
    }
}
