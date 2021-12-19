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
    @Binding var url: URL?
    
    var body: some View {
        List {
            Text("Bookmark 1")
            Text("Bookmark 2")
            Text("Bookmark 3")
        }
    }
}
