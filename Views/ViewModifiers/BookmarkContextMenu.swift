/*
65;6800;1c * This file is part of Kiwix for iOS & macOS.
 *
 * Kiwix is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * any later version.
 *
 * Kiwix is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Kiwix; If not, see https://www.gnu.org/licenses/.
*/

import SwiftUI

struct BookmarkContextMenu: ViewModifier {
    @Environment(\.managedObjectContext) private var managedObjectContext
    @EnvironmentObject private var navigation: NavigationViewModel

    let bookmark: Bookmark

    func body(content: Content) -> some View {
        content.contextMenu {
            Button {
                NotificationCenter.openURL(bookmark.articleURL)
            } label: {
                Label(LocalString.bookmark_context_menu_view_title, systemImage: "doc.richtext")
            }
            Button(role: .destructive) {
                managedObjectContext.delete(bookmark)
                try? managedObjectContext.save()
            } label: {
                Label(LocalString.bookmark_context_menu_remove_title, systemImage: "star.slash.fill")
            }
        }
    }
}
