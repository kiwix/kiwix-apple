//
//  LibraryZimFiles.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 12/31/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

struct LibraryZimFiles: View {
    @Binding var displayMode: LibraryDisplayMode?
    @SectionedFetchRequest(
        sectionIdentifier: \.name,
        sortDescriptors: [SortDescriptor(\.name), SortDescriptor(\.size, order: .reverse)],
        predicate: NSPredicate(format: "category == %@ AND languageCode == %@", "wikipedia", "en")
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
        }.task { try? await Database.shared.refreshOnlineZimFileCatalog() }.frame(minWidth: 500)
    }
}
