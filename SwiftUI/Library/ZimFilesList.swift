//
//  ZimFilesList.swift
//  Kiwix
//
//  Created by Chris Li on 4/24/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

import Defaults

/// A list of zim files of the same category.
struct ZimFilesList: View {
    @Default(.libraryLanguageCodes) private var languageCodes
    @FetchRequest private var zimFiles: FetchedResults<ZimFile>
    @State private var searchText = ""
    @State private var selected: ZimFile?
    
    let category: Category
    
    init(category: Category) {
        self.category = category
        self._zimFiles = FetchRequest<ZimFile>(
            sortDescriptors: [
                NSSortDescriptor(
                    key: "name", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare)
                ),
                NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)
            ],
            predicate: ZimFilesList.buildPredicate(category: category, searchText: ""),
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
        .navigationTitle(category.description)
        .modifier(ZimFileListStyle())
        .modifier(ZimFileDetailPanel(zimFile: selected))
        .modifier(Searchable(searchText: $searchText))
        .onChange(of: category) { _ in
            searchText = ""
            selected = nil
        }
        .onChange(of: searchText) { _ in
            if #available(iOS 15.0, *) {
                zimFiles.nsPredicate = ZimFilesList.buildPredicate(category: category, searchText: searchText)
            }
        }
        .onChange(of: languageCodes) { _ in
            if #available(iOS 15.0, *) {
                zimFiles.nsPredicate = ZimFilesList.buildPredicate(category: category, searchText: "")
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
}

private struct ZimFileListStyle: ViewModifier {
    func body(content: Content) -> some View {
        #if os(macOS)
        content.listStyle(.inset)
        #elseif os(iOS)
        content.listStyle(.plain)
        #endif
    }
}
