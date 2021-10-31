//
//  BookmarksViewController.swift
//  Kiwix
//
//  Created by Chris Li on 10/26/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI
import UIKit

import RealmSwift


class BookmarksViewController: UIHostingController<BookmarksView> {
    convenience init() {
        self.init(rootView: BookmarksView())
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Done", style: .done, target: self, action: #selector(dismissController)
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if splitViewController != nil {
            navigationController?.navigationBar.isHidden = true
        }
    }
    
    @objc private func dismissController() {
        dismiss(animated: true)
    }
}

struct BookmarksView: View {
    @ObservedResults(
        Bookmark.self,
        sortDescriptor: SortDescriptor(keyPath: "date", ascending: false)
    ) private var bookmarks
    
    var selected: (Bookmark) -> Void = { _ in }
    
    var body: some View {
        if bookmarks.isEmpty {
            VStack(spacing: 20) {
                ZStack {
                    Image(systemName: "star.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(20)
                        .foregroundColor(.secondary)
                    Circle().foregroundColor(.secondary).opacity(0.2)
                }.frame(width: 75, height: 75, alignment: .center)
                VStack(spacing: 6) {
                    Text("No bookmarked article.").font(Font.headline)
                    Text("To add, long press the bookmark button on the tool bar when reading an article.")
                        .multilineTextAlignment(.center)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }.padding(.horizontal)
            }.navigationBarTitle("Bookmarks")
        } else {
            List {
                ForEach(bookmarks) { bookmark in
                    Button { selected(bookmark) } label: {
                        HStack(alignment: bookmark.thumbImagePath == nil ? .center : .top) {
                            if let zimFile = bookmark.zimFile,
                               let path = bookmark.thumbImagePath,
                               let content = ZimFileService.shared.getURLContent(zimFileID: zimFile.fileID, contentPath: path) {
                                Favicon(data: content.data, contentMode: .fill, width: 18)
                            } else {
                                Favicon(data: bookmark.zimFile?.faviconData, width: 18)
                            }
                            VStack(alignment: .leading) {
                                Text(bookmark.title).fontWeight(.medium).lineLimit(1)
                                if let snippet = bookmark.snippet { Text(snippet).font(.caption).lineLimit(4) }
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationBarTitle("Bookmarks")
        }
    }
}
