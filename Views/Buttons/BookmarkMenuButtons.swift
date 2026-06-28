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

/// iOS only, when the buttons (show bookmars, add/remove bookmark)
/// appear as part of a menu under the more ... tab item
struct BookmarkMenuButtons: View {
    let articleBookmarked: Bool
    let isButtonDisabled: Bool
    let createBookmark: () -> Void
    let deleteBookmark: () -> Void
    let showBookmarks: () -> Void
    
    var body: some View {
        if articleBookmarked {
            Button(role: .destructive) {
                deleteBookmark()
            } label: {
                Label(LocalString.common_dialog_button_remove_bookmark, systemImage: "star.slash.fill")
            }
        } else {
            Button {
                createBookmark()
            } label: {
                Label(LocalString.common_dialog_button_add_bookmark, systemImage: "star")
            }
        }
        Button {
            showBookmarks()
        } label: {
            Label(LocalString.common_dialog_button_show_bookmarks, systemImage: "list.star")
        }
    }
}
#endif
