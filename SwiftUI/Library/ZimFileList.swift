//
//  ZimFileList.swift
//  Kiwix
//
//  Created by Chris Li on 4/24/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct ZimFileList: View {
    @FetchRequest private var zimFiles: FetchedResults<ZimFile>
    @State private var searchText = ""
    @State private var hovering: ZimFile?
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
            predicate: ZimFileList.buildPredicate(category: category, searchText: ""),
            animation: .easeInOut
        )
    }
    
    var body: some View {
        List(zimFiles, id: \.self, selection: $selected) { zimFile in
            HStack {
                if #available(iOS 15.0, *) {
                    Favicon(category: category, imageData: zimFile.faviconData, imageURL: zimFile.faviconURL)
                        .frame(height: 26)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(zimFile.name).lineLimit(1)
                    Text([
                        Library.dateFormatter.string(from: zimFile.created),
                        Library.sizeFormatter.string(fromByteCount: zimFile.size),
                        {
                            if #available(iOS 15.0, *) {
                                return "\(zimFile.articleCount.formatted(.number.notation(.compactName))) articles"
                            } else {
                                return Library.formattedLargeNumber(from: zimFile.articleCount)
                            }
                        }()
                    ].joined(separator: ", ")).font(.caption)
                }
            }
        }
        .listStyle(.inset)
        .navigationTitle(category.description)
        .modifier(ZimFileDetailPanel(zimFile: selected))
        .modifier(Searchable(searchText: $searchText))
        .onChange(of: searchText) { _ in
            if #available(iOS 15.0, *) {
                zimFiles.nsPredicate = ZimFileList.buildPredicate(category: category, searchText: searchText)
            }
        }
    }
    
    private static func buildPredicate(category: Category, searchText: String) -> NSPredicate {
        var predicates = [
            NSPredicate(format: "languageCode == %@", "en"),
            NSPredicate(format: "category == %@", category.rawValue)
        ]
        if !searchText.isEmpty {
            predicates.append(NSPredicate(format: "name CONTAINS[cd] %@", searchText))
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}
