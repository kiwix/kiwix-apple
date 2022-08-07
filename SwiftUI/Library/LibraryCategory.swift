//
//  LibraryCategory.swift
//  Kiwix
//
//  Created by Chris Li on 8/7/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct LibraryCategories: View {
    @State private var selected: Category = .wikipedia
    
    var body: some View {
        LibraryCategory(selectedCategory: $selected)
            .navigationTitle(NavigationItem.categories.name)
            .toolbar {
                Picker("Category", selection: $selected) {
                    ForEach(Category.allCases) { Text($0.name).tag($0) }
                }
            }
    }
}


struct LibraryCategory: View {
    @Binding var selectedCategory: Category
    @State private var searchText = ""
    @State private var selectedZimFile: ZimFile?
    
    var body: some View {
        Group {
            Text(selectedCategory.name)
        }
        .modifier(Searchable(searchText: $searchText))
        .modifier(ZimFileDetailPanel(zimFile: selectedZimFile))
    }
}
