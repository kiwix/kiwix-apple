//
//  ZimFilesOpened.swift
//  Kiwix
//
//  Created by Chris Li on 5/15/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

/// A grid of zim files that are opened, or was open but is now missing.
struct ZimFilesOpened: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.withFileURLBookmarkPredicate,
        animation: .easeInOut
    ) private var zimFiles: FetchedResults<ZimFile>
    @State private var isFileImporterPresented = false
    
    var body: some View {
        LazyVGrid(
            columns: ([GridItem(.adaptive(minimum: 250, maximum: 500), spacing: 12)]),
            alignment: .leading,
            spacing: 12
        ) {
            ForEach(zimFiles) { zimFile in
                ZimFileCell(zimFile, prominent: .name).modifier(LibraryZimFileContext(zimFile: zimFile))
            }
        }
        .modifier(GridCommon(edges: .all))
        .modifier(ToolbarRoleBrowser())
        .navigationTitle(NavigationItem.opened.name.localized)
        .overlay {
            if zimFiles.isEmpty {
                Message(text: "No opened zim file".localized)
            }
        }
        // not using OpenFileButton here, because it does not work on iOS/iPadOS 15 when this view is in a modal
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [UTType.zimFile],
            allowsMultipleSelection: true
        ) { result in
            guard case let .success(urls) = result else { return }
            NotificationCenter.openFiles(urls, context: .library)
        }
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarLeading) {
                if #unavailable(iOS 16), horizontalSizeClass == .regular {
                    Button {
                        NotificationCenter.toggleSidebar()
                    } label: {
                        Label("Show Sidebar".localized, systemImage: "sidebar.left")
                    }
                }
            }
            #endif
            ToolbarItem {
                Button {
                    // On iOS/iPadOS 15, fileimporter's isPresented binding is not reset to false if user swipe to dismiss
                    // the sheet. In order to mitigate the issue, the binding is set to false then true with a 0.1s delay.
                    isFileImporterPresented = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isFileImporterPresented = true
                    }
                    isFileImporterPresented = true
                } label: {
                    Label("Open...".localized, systemImage: "plus")
                }.help("Open a zim file".localized)
            }
        }
    }
}
