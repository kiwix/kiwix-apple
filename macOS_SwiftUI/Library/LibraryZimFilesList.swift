//
//  LibraryZimFilesList.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 1/7/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct LibraryZimFilesList: View {
    @Binding var displayMode: Library.DisplayMode?
    @Binding var selectedZimFile: ZimFile?
    @Binding var searchText: String
    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "category == %@", "does_not_exist")
    ) private var zimFiles: FetchedResults<ZimFile>
    
    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.flexible(minimum: 300, maximum: 500))],
                alignment: .center,
                spacing: 12,
                pinnedViews: []
            ) {
                ForEach(zimFiles) { zimFile in
                    ZimFileCell(zimFile, prominent: .title).onTapGesture { self.selectedZimFile = zimFile }
                }
            }.padding()
        }
        .searchable(text: $searchText)
        .onAppear {
            zimFiles.sortDescriptors = generateSortDescriptors()
            zimFiles.nsPredicate = generatePredicate()
        }
        .onChange(of: displayMode) { _ in
            zimFiles.sortDescriptors = generateSortDescriptors()
            zimFiles.nsPredicate = generatePredicate()
        }
        .onChange(of: searchText) { _ in
            zimFiles.nsPredicate = generatePredicate()
        }
    }
    
    private func generateSortDescriptors() -> [SortDescriptor<ZimFile>] {
        switch displayMode {
        case .new:
            return [SortDescriptor(\.created, order: .reverse)]
        default:
            return [SortDescriptor(\.size, order: .reverse)]
        }
    }
    
    private func generatePredicate() -> NSPredicate? {
        var predicates = [NSPredicate]()
        if !searchText.isEmpty {
            predicates.append(NSPredicate(format: "name CONTAINS[cd] %@", searchText))
        }
        
        switch displayMode {
        case .opened:
            predicates.append(NSPredicate(format: "fileURLBookmark != nil"))
        case .new:
            guard let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) else { return nil }
            predicates.append(contentsOf: [
                NSPredicate(format: "languageCode == %@", "en"),
                NSPredicate(format: "created > %@", twoWeeksAgo as CVarArg)
            ])
        case .downloads:
            predicates.append(NSPredicate(format: "category == %@", "placeholder"))
        case .category(let category) where category == .ted || category == .stackExchange:
            predicates.append(NSPredicate(format: "category == %@", category.rawValue))
        default:
            break
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}
