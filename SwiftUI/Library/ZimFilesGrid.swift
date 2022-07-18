//
//  ZimFilesGrid.swift
//  Kiwix
//
//  Created by Chris Li on 4/23/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

import Defaults

/// A grid of zim files of the same category broken down into sections by title.
@available(iOS 15.0, macOS 12.0, *)
struct ZimFilesGrid: View {
    @Default(.libraryLanguageCodes) private var languageCodes
    @SectionedFetchRequest private var sections: SectionedFetchResults<String, ZimFile>
    @State private var selected: ZimFile?
    
    let category: Category
    
    init(category: Category) {
        self.category = category
        self._sections = SectionedFetchRequest<String, ZimFile>(
            sectionIdentifier: \.name,
            sortDescriptors: [SortDescriptor(\ZimFile.name), SortDescriptor(\.size, order: .reverse)],
            predicate:  ZimFilesGrid.buildPredicate(category: category),
            animation: .easeInOut
        )
    }
    
    var body: some View {
        Group {
            if sections.isEmpty {
                Message(text: "No zim file under this category.")
            } else {
                LazyVGrid(
                    columns: ([gridItem]),
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
                }.modifier(GridCommon())
            }
        }
        .navigationTitle(category.description)
        .modifier(ZimFileDetailPanel(zimFile: selected))
        .onChange(of: category) { _ in selected = nil }
        .onChange(of: languageCodes) { _ in
            sections.nsPredicate = ZimFilesGrid.buildPredicate(category: category)
        }
    }
    
    private var gridItem: GridItem {
        #if os(macOS)
        GridItem(.adaptive(minimum: 200, maximum: 400), spacing: 12)
        #elseif os(iOS)
        GridItem(.adaptive(minimum: 175, maximum: 400), spacing: 12)
        #endif
    }
    
    private static func buildPredicate(category: Category) -> NSPredicate {
        NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "category == %@", category.rawValue),
            NSPredicate(format: "languageCode IN %@", Defaults[.libraryLanguageCodes]),
            NSPredicate(format: "requiresServiceWorkers == false")
        ])
    }
}

private struct SectionHeader: View {
    let title: String
    let category: Category
    let imageData: Data?
    let imageURL: URL?
    
    var body: some View {
        Label {
            Text(title).font(.title3).fontWeight(.semibold)
        } icon: {
            Favicon(category: category, imageData: imageData, imageURL: imageURL).frame(height: 20)
        }
    }
}

struct SectionHeader_Previews: PreviewProvider {
    static var previews: some View {
        SectionHeader(
            title: "Best of Wikipedia",
            category: .wikipedia,
            imageData: nil,
            imageURL: nil
        ).padding().previewLayout(.sizeThatFits).preferredColorScheme(.light)
        SectionHeader(
            title: "Best of Wikipedia",
            category: .wikipedia,
            imageData: nil,
            imageURL: nil
        ).padding().previewLayout(.sizeThatFits).preferredColorScheme(.dark)
    }
}
