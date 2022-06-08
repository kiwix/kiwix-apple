//
//  ZimFilesOpened.swift
//  Kiwix
//
//  Created by Chris Li on 5/15/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

/// Show a grid of zim files that are opened in the app.
struct ZimFilesOpened: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.openedPredicate,
        animation: .easeInOut
    ) private var zimFiles: FetchedResults<ZimFile>
    @State private var isFileImporterPresented: Bool = false
    @State private var selected: ZimFile?
    
    var body: some View {
        Group {
            if zimFiles.isEmpty {
                Message(text: "No zim file opened")
            } else {
                GeometryReader { proxy in
                    ScrollView {
                        LazyVGrid(
                            columns: ([GridItem(.adaptive(minimum: 250, maximum: 400), spacing: 12)]),
                            alignment: .leading,
                            spacing: 12
                        ) {
                            ForEach(zimFiles) { zimFile in
                                Button { selected = zimFile } label: { ZimFileCell(zimFile, prominent: .title) }
                                    .buttonStyle(.plain)
                                    .modifier(ZimFileContextMenu(selected: $selected, zimFile: zimFile))
                                    .modifier(ZimFileSelection(selected: $selected, zimFile: zimFile))
                            }
                        }.modifier(LibraryGridPadding(width: proxy.size.width))
                    }
                }
            }
        }
        .navigationTitle(LibraryTopic.opened.name)
        .modifier(ZimFileDetailPanel(zimFile: selected))
        .modifier(FileImporter(isPresented: $isFileImporterPresented))
        .toolbar {
            Button {
                isFileImporterPresented = true
            } label: {
                Image(systemName: "plus")
            }
            .help("Open a zim file")
        }
    }
}

struct ZimFilesOpened_Previews: PreviewProvider {
    static var previews: some View {
        ZimFilesOpened()
    }
}
