//
//  BookmarkButton.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 12/25/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import CoreData
import SwiftUI

struct BookmarkButton: View {
    @EnvironmentObject var viewModel: ReaderViewModel
    @FetchRequest private var bookmarks: FetchedResults<Bookmark>
    
    init(url: URL?) {
        self._bookmarks = FetchRequest<Bookmark>(sortDescriptors: [], predicate: {
            if let url = url {
                return NSPredicate(format: "articleURL == %@", url as CVarArg)
            } else {
                return NSPredicate(format: "articleURL == nil")
            }
        }())
    }
    
    var body: some View {
        Button {
            if isBookmarked {
                viewModel.deleteBookmark()
            } else {
                viewModel.createBookmark()
            }
        } label: {
            Image(systemName: isBookmarked ? "star.fill" : "star")
        }
        .disabled(viewModel.url == nil)
        .foregroundColor(isBookmarked ? .yellow : nil)
        .help(isBookmarked ? "Remove bookmark" : "Bookmark the current article")
    }
    
    private var isBookmarked: Bool {
        !bookmarks.isEmpty
    }
}
