//
//  LibraryZimFiles.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 12/31/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

struct LibraryZimFiles: View {
    @Binding var displayMode: Library.DisplayMode?
    @SectionedFetchRequest(
        sectionIdentifier: \.name,
        sortDescriptors: [SortDescriptor(\.name), SortDescriptor(\.size, order: .reverse)],
        predicate: NSPredicate(format: "fileURLBookmark != nil")
    ) private var zimFiles: SectionedFetchResults<String, ZimFile>
    
    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 200, maximum: 300), spacing: 12)],
                alignment: HorizontalAlignment.leading,
                spacing: 12,
                pinnedViews: [.sectionHeaders]
            ) {
                ForEach(zimFiles) { section in
                    Section {
                        ForEach(section) { zimFile in
                            ZimFileCell(zimFile: zimFile)
                        }
                    } header: {
                        LibrarySectionHeader(title: section.id)
                            .padding(.top, 12)
                            .padding(.bottom, -2)
                    }
                }
            }.padding()
        }
        .task { try? await Database.shared.refreshOnlineZimFileCatalog() }.frame(minWidth: 500)
        .onChange(of: displayMode) { displayMode in
            guard let displayMode = displayMode else { return }
            zimFiles.nsPredicate = generatePredicate(displayMode: displayMode)
        }
    }
    
    private func generatePredicate(displayMode: Library.DisplayMode) -> NSPredicate {
        switch displayMode {
        case .opened:
            return NSPredicate(format: "fileURLBookmark != nil")
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
            break
        }
        return NSPredicate(format: "languageCode == %@", "en")
    }
}
