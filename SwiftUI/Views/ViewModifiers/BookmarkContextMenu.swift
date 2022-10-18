//
//  BookmarkContextMenu.swift
//  Kiwix
//
//  Created by Chris Li on 9/17/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct BookmarkContextMenu: ViewModifier {
    @Binding var url: URL?
    @EnvironmentObject private var viewModel: ViewModel
    
    let bookmark: Bookmark
    
    func body(content: Content) -> some View {
        content.contextMenu {
            Button {
                url = bookmark.articleURL
            } label: {
                Label("View", systemImage: "doc.richtext")
            }
            if #available(iOS 15.0, *) {
                Button(role: .destructive) {
                    BookmarkOperations.delete(bookmark.articleURL, withNotification: false)
                } label: {
                    Label("Remove", systemImage: "star.slash.fill")
                }
            } else {
                Button {
                    BookmarkOperations.delete(bookmark.articleURL, withNotification: false)
                } label: {
                    Label("Remove", systemImage: "star.slash.fill")
                }
            }
        }
    }
}
