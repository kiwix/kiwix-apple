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
    @State private var selectedZimFile: ZimFile?
    
    let category: Category
    
    init(category: Category) {
        self.category = category
        self._zimFiles = FetchRequest<ZimFile>(
            sortDescriptors: [
                NSSortDescriptor(
                    key: "name", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare)
                )
            ],
            predicate: ZimFileList.buildPredicate(category: category, searchText: ""),
            animation: .easeInOut
        )
    }
    
    var body: some View {
        List(zimFiles) { zimFile in
            NavigationLink {
                Text("Detail about zim file: \(zimFile.name)")
            } label: {
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
        }
        .listStyle(.plain)
        .navigationTitle(category.description)
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
