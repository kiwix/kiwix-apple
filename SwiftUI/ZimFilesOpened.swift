//
//  ZimFilesOpened.swift
//  Kiwix
//
//  Created by Chris Li on 5/15/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

/// A grid of zim files that are opened, or was open but is now missing.
struct ZimFilesOpened: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.withFileURLBookmarkPredicate,
        animation: .easeInOut
    ) private var zimFiles: FetchedResults<ZimFile>
    @State private var selected: ZimFile?
    
    var body: some View {
        Group {
            if zimFiles.isEmpty {
                Message(text: "No opened zim file")
            } else {
                LazyVGrid(
                    columns: ([GridItem(.adaptive(minimum: 250, maximum: 500), spacing: 12)]),
                    alignment: .leading,
                    spacing: 12
                ) {
                    ForEach(zimFiles) { zimFile in
                        Button { selected = zimFile } label: { ZimFileCell(zimFile, prominent: .name) }
                            .buttonStyle(.plain)
                            .modifier(ZimFileContextMenu(selected: $selected, zimFile: zimFile))
                            .modifier(ZimFileSelection(selected: $selected, zimFile: zimFile))
                    }
                }.modifier(GridCommon())
            }
        }
        .navigationTitle(NavigationItem.opened.name)
        .modifier(ZimFileDetailPanel_macOS(zimFile: selected))
        .toolbar { FileImportButton() }
    }
}