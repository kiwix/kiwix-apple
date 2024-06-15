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

/// A grid of zim files that are opened, or was open but is now missing.
struct ZimFilesOpened: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.Predicate.isDownloaded,
        animation: .easeInOut
    ) private var zimFiles: FetchedResults<ZimFile>
    @State private var isFileImporterPresented = false
    @EnvironmentObject private var viewModel: LibraryViewModel
    let dismiss: (() -> Void)? // iOS only

    var body: some View {
        LazyVGrid(
            columns: ([GridItem(.adaptive(minimum: 250, maximum: 500), spacing: 12)]),
            alignment: .leading,
            spacing: 12
        ) {
            ForEach(zimFiles) { zimFile in
                ZimFileCell(zimFile, prominent: .name).modifier(LibraryZimFileContext(zimFile: zimFile,
                                                                                      dismiss: self.dismiss))
            }
        }
        .modifier(GridCommon(edges: .all))
        .modifier(ToolbarRoleBrowser())
        .navigationTitle(NavigationItem.opened.name)
        .overlay {
            if zimFiles.isEmpty {
                Message(text: "zim_file_opened.overlay.no-opened.message".localized)
            }
        }
        .onChange(of: zimFiles.count) { _ in
            viewModel.selectedZimFile = zimFiles.first // makes sure we also nil out, if all ZIMs were unlinked 
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
                        Label("zim_file_opened.toolbar.show_sidebar.label".localized, systemImage: "sidebar.left")
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
                    Label("zim_file_opened.toolbar.open.title".localized, systemImage: "plus")
                }.help("zim_file_opened.toolbar.open.help".localized)
            }
        }
    }
}
