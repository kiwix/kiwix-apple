//
//  Bookmarks.swift
//  Kiwix
//
//  Created by Chris Li on 5/28/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct Bookmarks: View {
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
            ForEach(bookmarks) { bookmark in
                Button {
                    NotificationCenter.default.post(
                        name: Notification.Name.openURL, object: nil, userInfo:  ["url": bookmark.articleURL]
                    )
                } label: {
                    ArticleCell(bookmark: bookmark).frame(height: itemHeight)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button {
                        NotificationCenter.default.post(
                            name: Notification.Name.openURL, object: nil, userInfo: ["url": bookmark.articleURL]
                        )
                    } label: {
                        Label("View", systemImage: "doc.richtext")
                    }
                    Button(role: .destructive) {
                        managedObjectContext.delete(bookmark)
                        try? managedObjectContext.save()
                    } label: {
                        Label("Remove", systemImage: "star.slash.fill")
                    }
                }
            }
        }
        .modifier(GridCommon())
        .navigationTitle("Bookmarks")
        .searchable(text: $searchText)
        .onChange(of: searchText) { searchText in
            bookmarks.nsPredicate = Bookmarks.buildPredicate(searchText: searchText)
        }
        .overlay {
            if bookmarks.isEmpty {
                Message(text: "No bookmarks")
            }
        }
        .modify { view in
            #if os(macOS)
            view
            #elseif os(iOS)
            if #available(iOS 16.0, *) {
                view.navigationBarTitleDisplayMode(.inline).toolbarRole(.browser)
            } else {
                view.navigationBarTitleDisplayMode(.inline)
            }
            #endif
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
