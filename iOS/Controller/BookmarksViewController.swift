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
    
    var body: some View {
        if bookmarks.isEmpty {
            VStack(spacing: 10) {
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
                }.padding()
            }.navigationBarTitle("Bookmarks")
        } else {
            List {
                ForEach(bookmarks) { bookmark in
                    Text(bookmark.title)
                }
            }
            .listStyle(.plain)
            .navigationBarTitle("Bookmarks")
        }
    }
}
