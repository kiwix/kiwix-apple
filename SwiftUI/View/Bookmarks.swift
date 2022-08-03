//
//  Bookmarks.swift
//  Kiwix
//
//  Created by Chris Li on 5/28/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct Bookmarks: View {
    @Binding var url: URL?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.presentationMode) private var presentationMode
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Bookmark.created, ascending: true)],
        animation: .easeInOut
    ) private var bookmarks: FetchedResults<Bookmark>
    
    var body: some View {
        Group {
            if bookmarks.isEmpty {
                Message(text: "No bookmarks")
            } else {
                LazyVGrid(columns: ([gridItem]), spacing: 12) {
                    ForEach(bookmarks) { bookmark in
                        Button { load(bookmark) } label: {
                            ArticleCell(bookmark: bookmark).frame(height: itemHeight)
                        }.buttonStyle(.plain)
                    }
                }.modifier(GridCommon())
            }
        }.navigationTitle("Bookmarks")
    }
    
    private var gridItem: GridItem {
        #if os(macOS)
        GridItem(.adaptive(minimum: 250, maximum: 500), spacing: 12)
        #elseif os(iOS)
        GridItem(.adaptive(minimum: 300, maximum: 500), spacing: 12)
        #endif
    }
    
    private var itemHeight: CGFloat? {
        #if os(macOS)
        80
        #elseif os(iOS)
        horizontalSizeClass == .regular ? 110: nil
        #endif
    }
    
    private func load(_ bookmark: Bookmark) {
        
    }
}
