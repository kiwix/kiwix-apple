//
//  LibraryZimFilesGrid.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 12/31/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

struct LibraryZimFilesGrid: View {
    @Binding var displayMode: Library.DisplayMode?
    @Binding var selectedZimFile: ZimFile?
    @Binding var searchText: String
    @SectionedFetchRequest(
        sectionIdentifier: \.name,
        sortDescriptors: [SortDescriptor(\.name), SortDescriptor(\.size, order: .reverse)],
        predicate: NSPredicate(format: "category == %@", "does_not_exist")
    ) private var zimFiles: SectionedFetchResults<String, ZimFile>
    
    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: ([GridItem(.adaptive(minimum: 200, maximum: 300), spacing: 12)]),
                alignment: .leading,
                spacing: 12,
                pinnedViews: [.sectionHeaders]
            ) {
                ForEach(zimFiles) { section in
                    if zimFiles.count <= 1 {
                        ForEach(section) { zimFile in
                            ZimFileCell(zimFile).onTapGesture { self.selectedZimFile = zimFile }
                        }
                    } else {
                        Section {
                            ForEach(section) { zimFile in
                                ZimFileCell(zimFile).onTapGesture { self.selectedZimFile = zimFile }
                            }
                        } header: {
                            LibrarySectionHeader(
                                title: section.id,
                                category: Category(rawValue: section.first?.category) ?? .other,
                                imageData: section.first?.faviconData,
                                imageURL: section.first?.faviconURL
                            )
                            .padding(.top, section.id == zimFiles.first?.id ? 0 : 12)
                            .padding(.bottom, -2)
                        }
                    }
                }
            }.padding()
        }
        .searchable(text: $searchText)
        .onAppear {
            zimFiles.nsPredicate = generatePredicate()
        }
        .onChange(of: displayMode) { _ in
            zimFiles.nsPredicate = generatePredicate()
        }
        .onChange(of: searchText) { _ in
            zimFiles.nsPredicate = generatePredicate()
        }
    }
    
    private func generatePredicate() -> NSPredicate? {
        var predicates = [NSPredicate(format: "languageCode == %@", "en")]
        if !searchText.isEmpty {
            predicates.append(NSPredicate(format: "name CONTAINS[cd] %@", searchText))
        }
        if case let .category(category) = displayMode {
            predicates.append(NSPredicate(format: "category == %@", category.rawValue))
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}
