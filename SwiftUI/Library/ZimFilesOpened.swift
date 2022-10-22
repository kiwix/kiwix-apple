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
    @Binding var url: URL?
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.withFileURLBookmarkPredicate,
        animation: .easeInOut
    ) private var zimFiles: FetchedResults<ZimFile>
    @State private var isFileImporterPresented = false
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
                        ZimFileCell(zimFile, prominent: .name)
                            .modifier(ZimFileContextMenu(selected: $selected, url: $url, zimFile: zimFile))
                            .modifier(ZimFileSelection(selected: $selected, url: $url, zimFile: zimFile))
                    }
                }.modifier(GridCommon())
            }
        }
        .navigationTitle(NavigationItem.opened.name)
        .modifier(ZimFileDetailPanel_macOS(url: $url, zimFile: selected))
        .toolbar {
            Button {
                // On iOS 14 & 15, fileimporter's isPresented binding is not reset to false if user swipe to dismiss
                // the sheet. In order to mitigate the issue, the binding is set to false then true with a 0.1s delay.
                isFileImporterPresented = false
                DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
                    isFileImporterPresented = true
                }
            } label: {
                Label("Open...", systemImage: "plus")
            }.help("Open a zim file")
        }
        // not using FileImportButton here, because it does not work on iOS/iPadOS, since this view is in a modal
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [Kiwix.zimFileType],
            allowsMultipleSelection: true
        ) { result in
            guard case let .success(urls) = result else { return }
            for url in urls {
                LibraryOperations.open(url: url)
            }
        }
    }
}
