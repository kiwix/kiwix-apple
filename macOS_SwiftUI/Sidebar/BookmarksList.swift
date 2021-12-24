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
    
    var body: some View {
        List(bookmarks, selection: $url) { bookmark in
            Text(bookmark.title)
        }
    }
}
