//
//  BookmarkContextMenu.swift
//  Kiwix
//
//  Created by Chris Li on 9/17/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct BookmarkContextMenu: ViewModifier {
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    let bookmark: Bookmark
    
    func body(content: Content) -> some View {
        content.contextMenu {
            Button {
                NotificationCenter.openURL(bookmark.articleURL)
            } label: {
                Label("View".localized, systemImage: "doc.richtext")
            }
            Button(role: .destructive) {
                managedObjectContext.delete(bookmark)
                try? managedObjectContext.save()
            } label: {
                Label("Remove".localized, systemImage: "star.slash.fill")
            }
        }
    }
}
