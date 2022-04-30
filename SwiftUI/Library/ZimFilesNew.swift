//
//  ZimFilesNew.swift
//  Kiwix
//
//  Created by Chris Li on 4/24/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct ZimFilesNew: View {
    @FetchRequest private var zimFiles: FetchedResults<ZimFile>
    @State private var searchText = ""
    @State private var selectedZimFile: ZimFile?
    
    init() {
        self._zimFiles = FetchRequest<ZimFile>(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \ZimFile.created, ascending: false),
                NSSortDescriptor(keyPath: \ZimFile.name, ascending: true),
                NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)
            ],
            predicate: ZimFilesNew.buildPredicate(searchText: ""),
            animation: .easeInOut
        )
    }
    
    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                LazyVGrid(
                    columns: ([GridItem(.adaptive(minimum: 250, maximum: 400), spacing: 12)]),
                    alignment: .leading,
                    spacing: 12
                ) {
                    ForEach(zimFiles) { zimFile in
                        ZimFileCell(zimFile, prominent: .title)
                            .modifier(ZimFileCellSelection(selected: $selectedZimFile, zimFile: zimFile))
                    }
                }.modifier(LibraryGridPadding(width: proxy.size.width))
            }
        }
        .navigationTitle(LibraryTopic.new.name)
        .modifier(Searchable(searchText: $searchText))
        .modifier(MacAdaptableContent(zimFile: $selectedZimFile))
        .onChange(of: searchText) { _ in
            if #available(iOS 15.0, *) {
                zimFiles.nsPredicate = ZimFilesNew.buildPredicate(searchText: searchText)
            }
        }
    }
    
    private static func buildPredicate(searchText: String) -> NSPredicate {
        var predicates = [NSPredicate(format: "languageCode == %@", "en")]
        if let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) {
            predicates.append(NSPredicate(format: "created > %@", twoWeeksAgo as CVarArg))
        }
        if !searchText.isEmpty {
            predicates.append(NSPredicate(format: "name CONTAINS[cd] %@", searchText))
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}
