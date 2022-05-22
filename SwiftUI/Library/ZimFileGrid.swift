//
//  ZimFileGrid.swift
//  Kiwix
//
//  Created by Chris Li on 4/23/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

@available(iOS 15.0, macOS 12.0, *)
struct ZimFileGrid: View {
    @SectionedFetchRequest private var sections: SectionedFetchResults<String, ZimFile>
    @State private var selected: ZimFile?
    
    let category: Category
    
    init(category: Category) {
        self.category = category
        self._sections = SectionedFetchRequest<String, ZimFile>(
            sectionIdentifier: \.name,
            sortDescriptors: [SortDescriptor(\ZimFile.name), SortDescriptor(\.size, order: .reverse)],
            predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "languageCode == %@", "en"),
                NSPredicate(format: "category == %@", category.rawValue)
            ]),
            animation: .easeInOut
        )
    }
    
    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                LazyVGrid(
                    columns: ([buildGridItem(gridWidth: proxy.size.width)]),
                    alignment: .leading,
                    spacing: 12
                ) {
                    ForEach(sections) { section in
                        if sections.count <= 1 {
                            ForEach(section) { zimFile in
                                Button { selected = zimFile } label: { ZimFileCell(zimFile, prominent: .size) }
                                    .buttonStyle(.plain)
                                    .modifier(ZimFileContextMenu(selected: $selected, zimFile: zimFile))
                                    .modifier(ZimFileSelection(selected: $selected, zimFile: zimFile))
                            }
                        } else {
                            Section {
                                ForEach(section) { zimFile in
                                    Button { selected = zimFile } label: { ZimFileCell(zimFile, prominent: .size) }
                                        .buttonStyle(.plain)
                                        .modifier(ZimFileContextMenu(selected: $selected, zimFile: zimFile))
                                        .modifier(ZimFileSelection(selected: $selected, zimFile: zimFile))
                                }
                            } header: {
                                SectionHeader(
                                    title: section.id,
                                    category: Category(rawValue: section.first?.category) ?? .other,
                                    imageData: section.first?.faviconData,
                                    imageURL: section.first?.faviconURL
                                ).padding(
                                    EdgeInsets(
                                        top: section.id == sections.first?.id ? 0 : 10,
                                        leading: 12,
                                        bottom: -6,
                                        trailing: 0
                                    )
                                )
                            }
                        }
                    }
                }.modifier(LibraryGridPadding(width: proxy.size.width))
            }
        }
        .navigationTitle(category.description)
        .modifier(ZimFileDetailPanel(zimFile: selected))
        .onChange(of: category) { _ in
            selected = nil
        }
    }
    
    private func buildGridItem(gridWidth: CGFloat) -> GridItem {
        #if os(macOS)
        GridItem(.adaptive(minimum: 150, maximum: 400), spacing: 12)
        #elseif os(iOS)
        GridItem(.adaptive(minimum: gridWidth > 375 ? 200 : 150, maximum: 400), spacing: 12)
        #endif
    }
}
