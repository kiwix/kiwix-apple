//
//  ZimFilesDownloads.swift
//  Kiwix
//
//  Created by Chris Li on 4/30/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import CoreData
import SwiftUI

/// A grid of zim files that are being downloaded.
struct ZimFilesDownloads: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DownloadTask.created, ascending: false)],
        animation: .easeInOut
    ) private var downloadTasks: FetchedResults<DownloadTask>
    
    var body: some View {
        LazyVGrid(
            columns: ([GridItem(.adaptive(minimum: 250, maximum: 500), spacing: 12)]),
            alignment: .leading,
            spacing: 12
        ) {
            ForEach(downloadTasks) { downloadTask in
                if let zimFile = downloadTask.zimFile {
                    DownloadTaskCell(downloadTask).modifier(LibraryZimFileContext(zimFile: zimFile))
                }
            }
        }
        .modifier(GridCommon())
        .modifier(ToolbarRoleBrowser())
        .navigationTitle(NavigationItem.downloads.name)
        .overlay {
            if downloadTasks.isEmpty {
                Message(text: "zim_file_downloads.overlay.empty.message".localized)
            }
        }
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarLeading) {
                if #unavailable(iOS 16), horizontalSizeClass == .regular {
                    Button {
                        NotificationCenter.toggleSidebar()
                    } label: {
                        Label("zim_file_downloads.toolbar.show_sidebar.label".localized, systemImage: "sidebar.left")
                    }
                }
            }
            #endif
        }
    }
}
