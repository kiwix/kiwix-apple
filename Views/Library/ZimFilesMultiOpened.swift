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

import Defaults
import SwiftUI
import UniformTypeIdentifiers

#if os(macOS)
/// A grid of zim files that are opened, or was open but is now missing.
/// A macOS specific version of ZimFilesOpened, supporting multi selection
struct ZimFilesMultiOpened: View {
    @State private var isFileImporterPresented = false
    @StateObject private var selection = MultiSelectedZimFilesViewModel()
    private let selectFileById = NotificationCenter.default.publisher(for: .selectFile)
    @State private var fileIdToOpen: UUID?
    @State private var showBy: ZIMsShowBy = Defaults[.openZIMsShowBy]
    @State private var sortBy: ZIMsSortBy = Defaults[.opneZIMsSorting]
    @FetchRequest private var zimFiles: FetchedResults<ZimFile>
    
    init() {
        _zimFiles = FetchRequest(
            sortDescriptors: [Defaults[.opneZIMsSorting].sortDescriptor()],
            predicate: ZimFile.openedPredicate(showBy: Defaults[.openZIMsShowBy]),
            animation: .easeInOut
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            LazyVGrid(
                columns: ([GridItem(.adaptive(minimum: 250, maximum: 500), spacing: 12)]),
                alignment: .leading,
                spacing: 12
            ) {
                ForEach(zimFiles, id: \.fileID) { zimFile in
                    MultiZimFilesContext(
                        content: {
                            ZimFileCell(
                                zimFile,
                                prominent: .name,
                                isSelected: selection.isSelected(zimFile)
                            )
                        },
                        zimFile: zimFile,
                        selection: selection)
                }
            }
            .modifier(GridCommon(edges: .all))
            .modifier(ToolbarRoleBrowser())
            .navigationTitle(MenuItem.opened.name)
            .overlay {
                if zimFiles.isEmpty {
                    Message(text: showBy.noResultsMessage)
                }
            }
            .onReceive(selectFileById, perform: { notification in
                guard let fileId = notification.userInfo?["fileId"] as? UUID else {
                    fileIdToOpen = nil
                    return
                }
                fileIdToOpen = fileId
            })
            .onChange(of: zimFiles.count) {
                let selectedZimFile: ZimFile?
                if let fileIdToOpen {
                    selectedZimFile = zimFiles.first { $0.fileID == fileIdToOpen }
                    self.fileIdToOpen = nil
                } else {
                    selectedZimFile = zimFiles.first
                }
                if let selectedZimFile {
                    selection.singleSelect(zimFile: selectedZimFile)
                } else {
                    selection.reset()
                }
            }
            .fileImporter(
                isPresented: $isFileImporterPresented,
                allowedContentTypes: [UTType.zimFile],
                allowsMultipleSelection: true
            ) { result in
                guard case let .success(urls) = result else { return }
                NotificationCenter.openFiles(urls, context: .library)
            }
            .toolbar {
                ZimFilters(sortBy: $sortBy, showBy: $showBy)
                
                ToolbarItem {
                    Button {
                        isFileImporterPresented = true
                    } label: {
                        Label(LocalString.zim_file_opened_toolbar_open_title, systemImage: "plus")
                    }.help(LocalString.zim_file_opened_toolbar_open_help)
                }
            }
            .safeAreaInset(edge: .trailing, spacing: 0) {
                HStack(spacing: 0) {
                    Divider()
                    switch selection.selectedZimFiles.count {
                    case 0:
                        Message(text: LocalString.library_zim_file_details_side_panel_message)
                            .background(.thickMaterial)
                    case 1:
                        ZimFileDetail(zimFile: selection.selectedZimFiles.first!, dismissParent: nil)
                    default:
                        MultiZimFilesDetail(zimFiles: selection.selectedZimFiles)
                    }
                }.frame(width: 275).background(.ultraThinMaterial)
            }
            .onChange(of: showBy) { (_, newValue: ZIMsShowBy) in
                Defaults[.openZIMsShowBy] = newValue
                zimFiles.nsPredicate = ZimFile.openedPredicate(showBy: newValue)
            }
            .onChange(of: sortBy) { (_, newValue: ZIMsSortBy) in
                Defaults[.opneZIMsSorting] = newValue
                zimFiles.sortDescriptors = [newValue.sortDescriptor()]
            }
        }
    }
}
#endif
