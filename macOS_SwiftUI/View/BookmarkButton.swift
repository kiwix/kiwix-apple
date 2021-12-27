//
//  BookmarkButton.swift
//  macOS_SwiftUI
//
//  Created by Chris Li on 12/25/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import CoreData
import SwiftUI

struct BookmarkButton: View {
    @FetchRequest private var bookmarks: FetchedResults<Bookmark>
    @EnvironmentObject var viewModel: SceneViewModel
    @Binding var url: URL?
    
    init(url: Binding<URL?>) {
        self._url = url
        self._bookmarks = FetchRequest<Bookmark>(sortDescriptors: [], predicate: {
            if let url = url.wrappedValue {
                return NSPredicate(format: "articleURL == %@", url as CVarArg)
            } else {
                return NSPredicate(format: "articleURL == nil")
            }
        }())
    }
    
    var body: some View {
        Button {
            if bookmarks.isEmpty {
                createBookmark()
            } else {
                deleteBookmark()
            }
        } label: {
            Image(systemName: bookmarks.isEmpty ? "star" : "star.fill")
        }.disabled(url == nil)
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
