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

import SwiftUI
import UniformTypeIdentifiers

#if os(iOS)

/// A grid of zim files that are opened, or was open but is now missing
/// iOS only, only iPad splitView
struct ZimFilesOpened: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.Predicate.isDownloaded(),
        animation: .easeInOut
    ) private var zimFiles: FetchedResults<ZimFile>
    @State private var isFileImporterPresented = false

    var body: some View {
        LazyVGrid(
            columns: ([GridItem(.adaptive(minimum: 250, maximum: 500), spacing: 12)]),
            alignment: .leading,
            spacing: 12
        ) {
            ForEach(zimFiles, id: \.fileID) { zimFile in
                NavigationLink(value: zimFile.fileID) {
                    ZimFileCell(
                        zimFile,
                        prominent: .name,
                        isSelected: false
                    )
                }.accessibilityIdentifier(zimFile.name)
            }
        }
        // reacts to both the above navigation link
        // and from the parent SplitViewForiPad's NavigationPath!
        .navigationDestination(for: UUID.self) { zimFileId in
            if let zimFile = zimFiles.first(where: { $0.fileID == zimFileId }) {
                ZimFileDetail(zimFile: zimFile, dismissParent: nil)
            }
        }
        .modifier(GridCommon(edges: .all))
        .modifier(ToolbarRoleBrowser())
        .navigationTitle(MenuItem.opened.name)
        .overlay {
            if zimFiles.isEmpty {
                Message(text: LocalString.zim_file_opened_overlay_no_opened_message)
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
            ToolbarItem {
                Button {
                    isFileImporterPresented = true
                } label: {
                    Label(LocalString.zim_file_opened_toolbar_open_title, systemImage: "plus")
                }.help(LocalString.zim_file_opened_toolbar_open_help)
            }
        }
    }
}
#endif
