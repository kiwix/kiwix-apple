//
//  ZimFileGrid.swift
//  Kiwix
//
//  Created by Chris Li on 4/23/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

@available(iOS 15.0, *)
struct ZimFileGrid: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @SectionedFetchRequest private var sections: SectionedFetchResults<String, ZimFile>
    @State private var selectedZimFile: ZimFile?
    
    let topic: LibraryTopic
    
    init(topic: LibraryTopic) {
        self.topic = topic
        self._sections = SectionedFetchRequest<String, ZimFile>(
            sectionIdentifier: \.name,
            sortDescriptors: [SortDescriptor(\ZimFile.name), SortDescriptor(\.size, order: .reverse)],
            predicate: topic.predicate
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
                                ZimFileCell(zimFile, prominent: .size)
                                    .modifier(ZimFileCellSelection(selected: $selectedZimFile, zimFile: zimFile))
                            }
                        } else {
                            Section {
                                ForEach(section) { zimFile in
                                    ZimFileCell(zimFile, prominent: .size)
                                        .modifier(ZimFileCellSelection(selected: $selectedZimFile, zimFile: zimFile))
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
        .navigationTitle(topic.name)
        .modifier(MacAdaptableContent(zimFile: $selectedZimFile))
    }
    
    private func buildGridItem(gridWidth: CGFloat) -> GridItem {
        #if os(macOS)
        GridItem(.adaptive(minimum: 150, maximum: 400), spacing: 12)
        #elseif os(iOS)
        GridItem(.adaptive(minimum: gridWidth > 375 ? 200 : 150, maximum: 400), spacing: 12)
        #endif
    }
}
