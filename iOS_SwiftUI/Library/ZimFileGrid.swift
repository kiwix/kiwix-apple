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
    @SectionedFetchRequest private var sections: SectionedFetchResults<String, ZimFile>

    let topic: Library.Topic
    
    init(topic: Library.Topic) {
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
                columns: ([GridItem(.adaptive(minimum: 250, maximum: 400), spacing: 12)]),
                alignment: .leading,
                spacing: 12,
                pinnedViews: [.sectionHeaders]
            ) {
                ForEach(sections) { section in
                    if sections.count <= 1 {
                        ForEach(section) { zimFile in
                            ZimFileCell(zimFile)
                        }
                    } else {
                        Section {
                            ForEach(section) { zimFile in
                                ZimFileCell(zimFile)
                            }
                        } header: {
                            Text(section.id)
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
