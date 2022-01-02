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
            zimFiles.nsPredicate = generatePredicate(displayMode: displayMode)
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
                    LibrarySectionHeader(title: section.id)
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
    
    private func generatePredicate(displayMode: Library.DisplayMode) -> NSPredicate? {
        switch displayMode {
        case .opened:
            return NSPredicate(format: "fileURLBookmark != nil")
        case .new:
            guard let aWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) else { return nil }
            return NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "languageCode == %@", "en"),
                NSPredicate(format: "created > %@", aWeekAgo as CVarArg)
            ])
        case .category(let category):
            switch category {
            case .ted, .stackExchange:
                return NSPredicate(format: "category == %@", category.rawValue)
            default:
                return NSCompoundPredicate(andPredicateWithSubpredicates: [
                    NSPredicate(format: "languageCode == %@", "en"),
                    NSPredicate(format: "category == %@", category.rawValue)
                ])
            }
        default:
            return NSPredicate(format: "languageCode == %@", "en")
        }
    }
}
