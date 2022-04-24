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
        ScrollView {
            LazyVGrid(
                columns: ([GridItem(.adaptive(minimum: horizontalSizeClass == .compact ? 150 : 250, maximum: 400), spacing: 12)]),
                alignment: .leading,
                spacing: 12
            ) {
                ForEach(sections) { section in
                    if sections.count <= 1 {
                        ForEach(section) { zimFile in
                            NavigationLink {
                                Text("Detail about zim file: \(zimFile.name)")
                            } label: {
                                ZimFileCell(zimFile)
                            }
                        }
                    } else {
                        Section {
                            ForEach(section) { zimFile in
                                NavigationLink {
                                    Text("Detail about zim file: \(zimFile.name)")
                                } label: {
                                    ZimFileCell(zimFile)
                                }
                            }
                        } header: {
                            SectionHeader(
                                title: section.id,
                                category: Category(rawValue: section.first?.category) ?? .other,
                                imageData: section.first?.faviconData,
                                imageURL: section.first?.faviconURL
                            ).padding(EdgeInsets(top: 10, leading: 12, bottom: -8, trailing: 0))
                        }
                    }
                }
            }.padding()
        }
        .navigationTitle(topic.name)
    }
}

@available(iOS 15.0, *)
struct ZimFileGrid_Previews: PreviewProvider {
    static var previews: some View {
        ZimFileGrid(topic: .new)
    }
}
