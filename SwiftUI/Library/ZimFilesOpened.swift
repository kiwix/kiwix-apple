//
//  ZimFilesOpened.swift
//  Kiwix
//
//  Created by Chris Li on 5/15/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

@available(iOS 15.0, macOS 12.0, *)
struct ZimFilesOpened: View {
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\ZimFile.size, order: .reverse)],
        predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "languageCode == %@", "en"),
            NSPredicate(format: "fileURLBookmark != nil")
        ]),
        animation: .easeInOut
    ) private var zimFiles: FetchedResults<ZimFile>
    @State private var isShowingFileImporter: Bool = false
    @State private var selected: ZimFile?
    
    var body: some View {
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
        .navigationTitle(LibraryTopic.new.name)
        .modifier(ZimFileDetailPanel(zimFile: selected))
        .toolbar {
            Button {
                isShowingFileImporter = true
            } label: {
                Image(systemName: "plus")
            }.modifier(FileImporter(isShowing: $isShowingFileImporter))
        }
    }
}
