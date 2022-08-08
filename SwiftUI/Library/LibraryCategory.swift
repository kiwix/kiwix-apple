//
//  LibraryCategory.swift
//  Kiwix
//
//  Created by Chris Li on 8/7/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

import Defaults

struct LibraryCategories: View {
    @State private var selected: Category = .wikipedia
    
    var body: some View {
        LibraryCategory(category: $selected)
            .navigationTitle(NavigationItem.categories.name)
            .toolbar {
                Picker("Category", selection: $selected) {
                    ForEach(Category.allCases) { Text($0.name).tag($0) }
                }
            }
    }
}


struct LibraryCategory: View {
    @Binding var category: Category
    @State private var searchText = ""
    
    var body: some View {
        if category == .ted || category == .stackExchange || category == .other {
            CategoryList(category: $category, searchText: $searchText)
        } else {
            CategoryGrid(searchText: $searchText, category: category)
        }
//        .modifier(Searchable(searchText: $searchText))
//        .modifier(ZimFileDetailPanel(zimFile: selectedZimFile))
    }
}

private struct CategoryGrid: View {
    @Binding var searchText: String
    
    let category: Category
    
    var body: some View {
        Text(category.name)
    }
}

private struct CategoryList: View {
    @Binding var category: Category
    @Binding var searchText: String
    @Default(.libraryLanguageCodes) private var languageCodes
    @FetchRequest private var zimFiles: FetchedResults<ZimFile>
    @State private var selected: ZimFile?
    
    init(category: Binding<Category>, searchText: Binding<String>) {
        self._category = category
        self._searchText = searchText
        self._zimFiles = FetchRequest<ZimFile>(
            sortDescriptors: [
                NSSortDescriptor(
                    key: "name", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare)
                ),
                NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)
            ],
            predicate: CategoryList.buildPredicate(
                category: category.wrappedValue, searchText: searchText.wrappedValue
            ),
            animation: .easeInOut
        )
    }
    
    var body: some View {
        Group {
            if zimFiles.isEmpty {
                Message(text: "No zim file under this category.")
            } else {
                List(zimFiles, id: \.self, selection: $selected) { zimFile in
                    ZimFileRow(zimFile)
                        .modifier(ZimFileContextMenu(selected: $selected, zimFile: zimFile))
                        .modifier(ZimFileSelection(selected: $selected, zimFile: zimFile))
                }
            }
        }
        .modifier(ListStyle())
        .modifier(ZimFileDetailPanel(zimFile: selected))
        .modifier(Searchable(searchText: $searchText))
        .onChange(of: category) { _ in selected = nil }
        .onChange(of: searchText) { _ in
            if #available(iOS 15.0, *) {
                zimFiles.nsPredicate = CategoryList.buildPredicate(category: category, searchText: searchText)
            }
        }
        .onChange(of: languageCodes) { _ in
            if #available(iOS 15.0, *) {
                zimFiles.nsPredicate = CategoryList.buildPredicate(category: category, searchText: searchText)
            }
        }
    }
    
    private static func buildPredicate(category: Category, searchText: String) -> NSPredicate {
        var predicates = [
            NSPredicate(format: "category == %@", category.rawValue),
            NSPredicate(format: "languageCode IN %@", Defaults[.libraryLanguageCodes]),
            NSPredicate(format: "requiresServiceWorkers == false")
        ]
        if !searchText.isEmpty {
            predicates.append(NSPredicate(format: "name CONTAINS[cd] %@", searchText))
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
    
    struct ListStyle: ViewModifier {
        func body(content: Content) -> some View {
            #if os(macOS)
            content.listStyle(.inset)
            #elseif os(iOS)
            content.listStyle(.plain)
            #endif
        }
    }
}


