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
import Defaults

/// Displays a grid of available local ZIM files. Used on new tab.
struct LocalLibraryList: View {
    private let load: (URL) -> Void
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Bookmark.created, ascending: false)],
        animation: .easeInOut
    ) private var bookmarks: FetchedResults<Bookmark>
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.openedPredicate,
        animation: .easeInOut
    ) private var zimFiles: FetchedResults<ZimFile>
    
    init(browser: BrowserViewModel) {
        load = browser.load(url:)
    }

    var body: some View {
        LazyVGrid(
            columns: ([GridItem(.adaptive(minimum: 250, maximum: 500), spacing: 12)]),
            alignment: .leading,
            spacing: 12
        ) {
            GridSection(title: LocalString.welcome_main_page_title) {
                ForEach(zimFiles) { zimFile in
                    AsyncButtonView {
                        guard let url = await ZimFileService.shared
                            .getMainPageURL(zimFileID: zimFile.fileID) else { return }
                        load(url)
                    } label: {
                        ZimFileCell(zimFile, prominent: .name)
                    } loading: {
                        ZimFileCell(zimFile, prominent: .name, isLoading: true)
                    }
                    .buttonStyle(.plain)
                }
            }
            if !bookmarks.isEmpty {
                GridSection(title: LocalString.welcome_grid_bookmarks_title) {
                    ForEach(bookmarks.prefix(6)) { bookmark in
                        Button {
                            load(bookmark.articleURL)
                        } label: {
                            ArticleCell(bookmark: bookmark)
                        }
                        .buttonStyle(.plain)
                        .modifier(BookmarkContextMenu(bookmark: bookmark))
                    }
                }
            }
        }.modifier(GridCommon(edges: .all))
    }
}
