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
    
    #if os(macOS)
    @EnvironmentObject private var multiSelectViewModel: LibraryMultiSelectViewModel
    #endif
    
    private func isSelected(_ zimFile: ZimFile) -> Bool {
#if os(macOS)
        multiSelectViewModel.selectedZimFiles.contains(zimFile)
#else
        viewModel.selectedZimFile == zimFile
#endif
    }

    var body: some View {
        LazyVGrid(
            columns: ([GridItem(.adaptive(minimum: 250, maximum: 500), spacing: 12)]),
            alignment: .leading,
            spacing: 12
        ) {
            ForEach(zimFiles) { zimFile in
                #if os(macOS)
                let multiSelected = { [zimFile] isMulti in
                    if isMulti {
                        multiSelectViewModel.toggleMultiSelect(of: zimFile)
                    } else {
                        multiSelectViewModel.singleSelect(zimFile: zimFile)
                    }
                }
                #else
                let multiSelected = nil
                #endif
                
                LibraryZimFileContext(
                    content: {
                        ZimFileCell(
                            zimFile,
                            prominent: .name,
                            isSelected: isSelected(zimFile)
                        )
                    },
                    zimFile: zimFile,
                    onMultiSelected: multiSelected,
                    dismiss: dismiss)
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
        .onChange(of: zimFiles.count) { _ in
            viewModel.selectedZimFile = zimFiles.first // makes sure we also nil out, if all ZIMs were unlinked
            #if os(macOS)
            if let firstZimFile = zimFiles.first {
                multiSelectViewModel.singleSelect(zimFile: firstZimFile)
            } else {
                multiSelectViewModel.resetSelection()
            }
            #endif
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
                        Label(LocalString.zim_file_opened_toolbar_show_sidebar_label, systemImage: "sidebar.left")
                    }
                }
            }
            #endif
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
