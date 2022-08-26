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
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DownloadTask.created, ascending: false)],
        animation: .easeInOut
    ) private var downloadTasks: FetchedResults<DownloadTask>
    @State private var selected: ZimFile?
    
    var body: some View {
        Group {
            if downloadTasks.isEmpty {
                Message(text: "No download tasks")
            } else {
                LazyVGrid(
                    columns: ([GridItem(.adaptive(minimum: 250, maximum: 500), spacing: 12)]),
                    alignment: .leading,
                    spacing: 12
                ) {
                    ForEach(downloadTasks) { downloadTask in
                        if let zimFile = downloadTask.zimFile {
                            Button { selected = zimFile } label: { DownloadTaskCell(downloadTask) }
                                .buttonStyle(.plain)
                                .modifier(ZimFileContextMenu(selected: $selected, zimFile: zimFile))
                                .modifier(ZimFileSelection(selected: $selected, zimFile: zimFile))
                        }
                    }
                }.modifier(GridCommon())
            }
        }
        .navigationTitle(NavigationItem.downloads.name)
        .modifier(ZimFileDetailPanel_macOS(zimFile: selected))
    }
}
