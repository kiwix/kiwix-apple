//
//  ZimFilesNew.swift
//  Kiwix
//
//  Created by Chris Li on 4/24/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

@available(iOS 15.0, *)
struct ZimFilesNew: View {
    @FetchRequest private var zimFiles: FetchedResults<ZimFile>
    @State private var searchText = ""
    @State private var selectedZimFile: ZimFile?
    
    init() {
        self._zimFiles = FetchRequest<ZimFile>(
            sortDescriptors: [
                SortDescriptor(\.created, order: .reverse),
                SortDescriptor(\.name),
                SortDescriptor(\.size, order: .reverse)
            ],
            predicate: LibraryTopic.new.predicate
        )
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: ([GridItem(.adaptive(minimum: 250, maximum: 400), spacing: 12)]),
                alignment: .leading,
                spacing: 12
            ) {
                ForEach(zimFiles) { zimFile in
                    #if os(macOS)
                    ZimFileCell(zimFile, prominent: .title)
                    #elseif os(iOS)
                    NavigationLink(tag: zimFile, selection: $selectedZimFile) {
                        Text("Detail about zim file: \(zimFile.name)")
                    } label: {
                        ZimFileCell(zimFile, prominent: .title)
                    }
                    #endif
                }
            }.padding([.horizontal, .bottom])
        }
        .navigationTitle(LibraryTopic.new.name)
        .searchable(text: $searchText)
        .onChange(of: searchText) { _ in
            updatePredicate()
        }
    }
    
    private func updatePredicate() {
        var predicates = [NSPredicate(format: "languageCode == %@", "en")]
        if let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) {
            predicates.append(NSPredicate(format: "created > %@", twoWeeksAgo as CVarArg))
        }
        if !searchText.isEmpty {
            predicates.append(NSPredicate(format: "name CONTAINS[cd] %@", searchText))
        }
        zimFiles.nsPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}
