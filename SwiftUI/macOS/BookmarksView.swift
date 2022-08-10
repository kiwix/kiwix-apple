//
//  BookmarksView.swift
//  Kiwix
//
//  Created by Chris Li on 5/28/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct BookmarksView: View {
    @Binding var url: URL?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.presentationMode) private var presentationMode
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Bookmark.created, ascending: true)],
        predicate: BookmarksView.buildPredicate(searchText: ""),
        animation: .easeInOut
    ) private var bookmarks: FetchedResults<Bookmark>
    @State private var searchText = ""
    
    var body: some View {
        Group {
            if bookmarks.isEmpty {
                Message(text: "No bookmarks")
            } else {
                LazyVGrid(columns: ([gridItem]), spacing: 12) {
                    ForEach(bookmarks) { bookmark in
                        Button { url = bookmark.articleURL } label: {
                            ArticleCell(bookmark: bookmark).frame(height: itemHeight)
                        }.buttonStyle(.plain)
                    }
                }.modifier(GridCommon())
            }
        }
        .navigationTitle("Bookmarks")
        .modifier(Searchable(searchText: $searchText))
        .onChange(of: searchText) { _ in
            if #available(iOS 15.0, *) {
                bookmarks.nsPredicate = BookmarksView.buildPredicate(searchText: searchText)
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
    
    private var itemHeight: CGFloat? {
        #if os(macOS)
        82
        #elseif os(iOS)
        horizontalSizeClass == .regular ? 110: nil
        #endif
    }
    
    private static func buildPredicate(searchText: String) -> NSPredicate? {
        guard !searchText.isEmpty else { return nil }
        return NSCompoundPredicate(orPredicateWithSubpredicates: [
            NSPredicate(format: "title CONTAINS[cd] %@", searchText),
            NSPredicate(format: "snippet CONTAINS[cd] %@", searchText)
        ])
    }
}
