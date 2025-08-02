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

#if os(iOS)

import SwiftUI
import UniformTypeIdentifiers

/// A grid of zim files that are opened, or was open but is now missing
/// iOS only
struct ZimFilesOpenedNavStack: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.Predicate.isDownloaded,
        animation: .easeInOut
    ) private var zimFiles: FetchedResults<ZimFile>
    @State private var isFileImporterPresented = false
    @State private var navPath: [ZimFile] = []
    // opening the details of a freshly added zimFile
    private let selectFileById = NotificationCenter.default.publisher(for: .selectFile)
    @State private var fileIdToOpen: UUID?
    
    let dismiss: (() -> Void)?
    
    var body: some View {
        NavigationStack(path: $navPath) {
            LazyVGrid(
                columns: ([GridItem(.adaptive(minimum: 250, maximum: 500), spacing: 12)]),
                alignment: .leading,
                spacing: 12
            ) {
                ForEach(zimFiles) { zimFile in
                    NavigationLink(value: zimFile) {
                        ZimFileCell(
                            zimFile,
                            prominent: .name,
                            isSelected: navPath.contains(where: { $0.fileID == zimFile.fileID })
                        )
                    }.accessibilityIdentifier(zimFile.name)
                }
            }
            .navigationDestination(for: ZimFile.self) { zimFile in
                ZimFileDetail(zimFile: zimFile, dismissParent: dismiss)
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isFileImporterPresented = true
                } label: {
                    Label(LocalString.zim_file_opened_toolbar_open_title, systemImage: "plus")
                }.help(LocalString.zim_file_opened_toolbar_open_help)
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
        .onReceive(selectFileById, perform: { notification in
            guard let fileId = notification.userInfo?["fileId"] as? UUID else {
                return
            }
            fileIdToOpen = fileId
        })
        .onChange(of: zimFiles.count) { _ in
            if let fileIdToOpen,
               let selectedZimFile = zimFiles.first(where: { $0.fileID == fileIdToOpen }) {
                self.fileIdToOpen = nil
                navPath = [selectedZimFile]
            }
        }
    }
}

#endif
