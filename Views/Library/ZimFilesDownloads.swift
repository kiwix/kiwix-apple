// This file is part of Kiwix for iOS & macOS.
//
// Kiwix is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// any later version.
//
// Kiwix is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Kiwix; If not, see https://www.gnu.org/licenses/.

import CoreData
import SwiftUI

/// A grid of zim files that are being downloaded.
struct ZimFilesDownloads: View {
    @EnvironmentObject var selection: SelectedZimFileViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DownloadTask.created, ascending: false)],
        predicate: NSPredicate(format: "zimFile != NULL"),
        animation: .easeInOut
    ) private var downloadTasks: FetchedResults<DownloadTask>
    private let dismiss: (() -> Void)?

    init(dismiss: (() -> Void)?) {
        self.dismiss = dismiss
    }

    var body: some View {
        LazyVGrid(
            columns: ([GridItem(.adaptive(minimum: 250, maximum: 500), spacing: 12)]),
            alignment: .leading,
            spacing: 12
        ) {
            ForEach(downloadTasks, id: \.fileID) { downloadTask in
                if let zimFile = downloadTask.zimFile, zimFile.downloadTask != nil {
                    LibraryZimFileContext(
                        content: { DownloadTaskCell(zimFile) },
                        zimFile: zimFile,
                        selection: selection,
                        dismiss: dismiss)
                }
            }
        }
        .modifier(GridCommon())
        .modifier(ToolbarRoleBrowser())
        .navigationTitle(MenuItem.downloads.name)
        .overlay {
            if downloadTasks.isEmpty {
                Message(text: LocalString.zim_file_downloads_overlay_empty_message)
            }
        }
    }
}
