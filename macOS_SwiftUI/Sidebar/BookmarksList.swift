//
//  BookmarksList.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 12/21/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

import RealmSwift

/// List of bookmarked article
struct BookmarksList: View {
    @FetchRequest(sortDescriptors: [
        SortDescriptor(\.created, order: .reverse)
    ]) private var bookmarks: FetchedResults<Bookmark>
    @Binding var url: URL?
    @State var searchText: String = ""
    
    var body: some View {
        SearchField(searchText: $searchText).padding(.horizontal, 10).padding(.vertical, 6)
        List(bookmarks, selection: $url) { bookmark in
            Text(bookmark.title)
        }
    }
}
