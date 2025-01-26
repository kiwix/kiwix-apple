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

#if os(iOS)
struct TabLabel: View {
    @ObservedObject var tab: Tab

    var body: some View {
        if let zimFile = tab.zimFile, let category = Category(rawValue: zimFile.category) {
            Label {
                Text(tab.title ?? LocalString.common_tab_menu_new_tab).lineLimit(1)
            } icon: {
                Favicon(category: category, imageData: zimFile.faviconData).frame(width: 22, height: 22)
            }
        } else {
            Label(tab.title ?? LocalString.common_tab_menu_new_tab, systemImage: "square")
        }
    }
}
#endif
