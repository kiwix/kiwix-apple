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
                deleteBookmark()
            } else {
                createBookmark()
            }
        } label: {
            Image(systemName: bookmarks.isEmpty ? "star" : "star.fill")
        }
        .disabled(viewModel.url == nil)
        .foregroundColor(isBookmarked ? .yellow : nil)
        .help(isBookmarked ? "Remove bookmark" : "Bookmark the current article")
        .onChange(of: viewModel.url) { url in
            if let url = url {
                bookmarks.nsPredicate = NSPredicate(format: "articleURL == %@", url as CVarArg)
            } else {
                bookmarks.nsPredicate = NSPredicate(format: "articleURL == nil")
            }
        }
    }
    
    var isBookmarked: Bool {
        !bookmarks.isEmpty
    }
    
    private func createBookmark() {
        guard let url = viewModel.webView.url, let title = viewModel.webView.title else { return }
        let context = Database.shared.container.viewContext
        let bookmark = Bookmark(context: context)
        bookmark.articleURL = url
        bookmark.title = title
        bookmark.created = Date()
        try? context.save()
    }
    
    private func deleteBookmark() {
        guard let url = viewModel.webView.url else { return }
        let context = Database.shared.container.viewContext
        let request = Bookmark.fetchRequest()
        request.predicate = NSPredicate(format: "articleURL == %@", url as CVarArg)
        guard let bookmark = try? context.fetch(request).first else { return }
        context.delete(bookmark)
        try? context.save()
    }
}
