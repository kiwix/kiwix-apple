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
    @Environment(\.presentationMode) private var presentationMode
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Bookmark.created, ascending: true)],
        animation: .easeInOut
    ) private var bookmarks: FetchedResults<Bookmark>
    
    var body: some View {
        if bookmarks.isEmpty {
            Message(text: "No bookmarks")
        } else {
            List(bookmarks, id: \.articleURL, selection: $url) { bookmark in
                #if os(macOS)
                Text(bookmark.title)
                #elseif os(iOS)
                Button {
                    url = bookmark.articleURL
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    VStack {
                        Text(bookmark.title)
                        if let snippet = bookmark.snippet {
                            Text(snippet).font(.caption)
                        }
                    }
                }
                #endif
            }
        }
    }
}

#if os(iOS)
struct BookmarksSheet: View {
    @Binding var url: URL?
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        NavigationView {
            Bookmarks(url: $url)
                .listStyle(.plain)
                .navigationTitle("Bookmarks")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Done") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
        }
    }
}
#endif
