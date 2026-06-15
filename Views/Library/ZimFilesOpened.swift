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
import Defaults
import SwiftUI
import UniformTypeIdentifiers

/// A grid of zim files that are opened, or was open but is now missing
/// iOS only, only iPad splitView
struct ZimFilesOpened: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isFileImporterPresented = false
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
                }.accessibilityIdentifier("Open: " + zimFile.name)
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
                Message(text: showBy.noResultsMessage)
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
            ZimFilters(sortBy: $sortBy, showBy: $showBy)
            
            // import file
            ToolbarItem {
                Button {
                    isFileImporterPresented = true
                } label: {
                    Label(LocalString.zim_file_opened_toolbar_open_title, systemImage: "plus")
                }.help(LocalString.zim_file_opened_toolbar_open_help)
            }
        }
        .controlGroupStyle(.palette)
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
#endif
