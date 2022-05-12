//
//  ZimFilesDownloads.swift
//  Kiwix
//
//  Created by Chris Li on 4/30/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct ZimFilesDownloads: View {
    @FetchRequest private var downloadTasks: FetchedResults<DownloadTask>
    @State private var searchText = ""
    @State private var selectedZimFile: ZimFile?
    
    init() {
        self._downloadTasks = FetchRequest<DownloadTask>(
            sortDescriptors: [NSSortDescriptor(keyPath: \DownloadTask.created, ascending: false)],
            animation: .easeInOut
        )
    }
    
    var body: some View {
        List(downloadTasks) { downloadTask in
            if #available(iOS 15.0, *) {
                Text(downloadTask.zimFile?.name ?? "Unknown").contextMenu {
                    Button("Cancel") {
                        Downloads.shared.cancel(zimFileID: downloadTask.fileID)
                    }
                }
            } else {
                Text(downloadTask.zimFile?.name ?? "Unknown")
            }
        }
    }
}

struct ZimFilesDownloads_Previews: PreviewProvider {
    static var previews: some View {
        ZimFilesDownloads()
    }
}
