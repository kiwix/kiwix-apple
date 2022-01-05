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
    @Binding var zimFile: ZimFile?
    @State var searchText: String = ""
    @SectionedFetchRequest(
        sectionIdentifier: \.name,
        sortDescriptors: [SortDescriptor(\.name), SortDescriptor(\.size, order: .reverse)],
        predicate: NSPredicate(format: "fileURLBookmark != nil")
    ) private var zimFiles: SectionedFetchResults<String, ZimFile>
    
    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: (
                    isFlattened ?
                    [GridItem(.adaptive(minimum: 300, maximum: 500), spacing: 12)] :
                    [GridItem(.adaptive(minimum: 200, maximum: 300), spacing: 12)]
                ),
                alignment: isFlattened ? .center : .leading,
                spacing: 12,
                pinnedViews: [.sectionHeaders]
            ) {
                if isFlattened {
                    flattened
                } else {
                    sectioned
                }
            }.padding()
        }
        .task { try? await Database.shared.refreshOnlineZimFileCatalog() }
        .searchable(text: $searchText)
        .onChange(of: displayMode) { displayMode in
            guard let displayMode = displayMode else { return }
            zimFiles.sortDescriptors = generateSortDescriptors(displayMode: displayMode)
            zimFiles.nsPredicate = generatePredicate()
        }
        .onChange(of: searchText) { _ in
            zimFiles.nsPredicate = generatePredicate()
        }
    }
    
    private var isFlattened: Bool {
        switch displayMode {
        case .opened, .new:
            return true
        case .category(let category):
            return category == .ted || category == .stackExchange
        default:
            return false
        }
    }
    
    private var flattened: some View {
        ForEach(zimFiles.flatMap { $0 }) { zimFile in
            ZimFileCell(zimFile, prominent: .title).onTapGesture { self.zimFile = zimFile }
        }
    }
    
    private var sectioned: some View {
        ForEach(zimFiles) { section in
            if zimFiles.count <= 1 {
                ForEach(section) { zimFile in
                    ZimFileCell(zimFile).onTapGesture { self.zimFile = zimFile }
                }
            } else {
                Section {
                    ForEach(section) { zimFile in
                        ZimFileCell(zimFile).onTapGesture { self.zimFile = zimFile }
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
    }
    
    private func generateSortDescriptors(displayMode: Library.DisplayMode) -> [SortDescriptor<ZimFile>] {
        switch displayMode {
        case .new:
            return [SortDescriptor(\.created, order: .reverse)]
        default:
            return [SortDescriptor(\.name), SortDescriptor(\.size, order: .reverse)]
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
        case .category(let category):
            switch category {
            case .ted, .stackExchange:
                predicates.append(NSPredicate(format: "category == %@", category.rawValue))
            default:
                predicates.append(contentsOf: [
                    NSPredicate(format: "languageCode == %@", "en"),
                    NSPredicate(format: "category == %@", category.rawValue)
                ])
            }
        case .none:
            break
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}