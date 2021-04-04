//
//  LibraryCategoryView.swift
//  Kiwix
//
//  Created by Chris Li on 4/4/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI
import RealmSwift

@available(iOS 14.0, *)
struct LibraryCategoryView: View {
    @State private var showingPopover = false
    
    let category: ZimFile.Category
    var languageFilterButtonTapped: () -> Void = {}
    
    var body: some View {
        Text("Hello, World!")
    }
}
