//
//  ZimFileGrid.swift
//  Kiwix
//
//  Created by Chris Li on 4/24/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

@available(iOS 15.0, *)
struct ZimFileGrid: View {
    @FetchRequest private var zimFiles: FetchedResults<ZimFile>
    
    let topic: LibraryTopic
    
    init(topic: LibraryTopic) {
        self.topic = topic
        self._zimFiles = FetchRequest<ZimFile>(
            sortDescriptors: [
                SortDescriptor(\.created, order: .reverse),
                SortDescriptor(\ZimFile.name),
                SortDescriptor(\.size, order: .reverse)
            ],
            predicate: topic.predicate
        )
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: ([GridItem(.adaptive(minimum: 250, maximum: 400), spacing: 12)]),
                alignment: .leading,
                spacing: 12
            ) {
                ForEach(zimFiles) { zimFile in
                    NavigationLink {
                        Text("Detail about zim file: \(zimFile.name)")
                    } label: {
                        ZimFileCell(zimFile, prominent: .title)
                    }.contextMenu {
                        Button("Download") {
                            
                        }
                    }
                }
            }.padding()
        }
        .navigationTitle(topic.name)
    }
}
