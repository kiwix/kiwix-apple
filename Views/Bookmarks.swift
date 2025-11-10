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

struct Bookmarks: View {
    @EnvironmentObject private var navigation: NavigationViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.managedObjectContext) private var managedObjectContext
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.created, order: .reverse)],
        predicate: Bookmarks.buildPredicate(searchText: ""),
        animation: .easeInOut
    ) private var bookmarks: FetchedResults<Bookmark>
    @State private var searchText = ""

    var body: some View {
        LazyVGrid(columns: ([gridItem]), spacing: 12) {
            ForEach(bookmarks, id: \.self) { bookmark in
                Button {
                    NotificationCenter.openURL(bookmark.articleURL)
                    if horizontalSizeClass == .compact {
                        dismiss()
                    }
                } label: {
                    ArticleCell(bookmark: bookmark)
                }
                .buttonStyle(.plain)
                .modifier(BookmarkContextMenu(bookmark: bookmark))
            }
        }
        .modifier(GridCommon())
        .modifier(ToolbarRoleBrowser())
        .navigationTitle(LocalString.bookmark_navigation_title)
        .searchable(text: $searchText, prompt: LocalString.common_search)
        .onChange(of: searchText) { _, newValue in
            bookmarks.nsPredicate = Bookmarks.buildPredicate(searchText: newValue)
        }
        .overlay {
            if bookmarks.isEmpty {
                Message(text: LocalString.bookmark_overlay_empty_title)
            }
        }
    }

    private var gridItem: GridItem {
        #if os(macOS)
        GridItem(.adaptive(minimum: 250, maximum: 500), spacing: 12)
        #elseif os(iOS)
        GridItem(.adaptive(minimum: 250, maximum: 500), spacing: 12)
        #endif
    }

    private static func buildPredicate(searchText: String) -> NSPredicate? {
        let searchPredicate: NSPredicate? = if searchText.isEmpty {
            nil
        } else {
            NSPredicate(format: "title CONTAINS[cd] %@", searchText)
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            searchPredicate,
            NSPredicate(format: "zimFile.isMissing == false")
        ].compactMap { $0 })
    }
}
