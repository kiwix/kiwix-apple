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
/// iOS only
struct ZimFilesOpenedNavStack: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isFileImporterPresented = false
    @State private var navPath: [ZimFile] = []
    // opening the details of a freshly added zimFile
    private let selectFileById = NotificationCenter.default.publisher(for: .selectFile)
    @State private var fileIdToOpen: UUID?
    @State private var showBy: ZIMsShowBy = Defaults[.openZIMsShowBy]
    @State private var sortBy: ZIMsSortBy = Defaults[.opneZIMsSorting]
    @FetchRequest private var zimFiles: FetchedResults<ZimFile>
    
    let dismiss: (() -> Void)?
    
    init(dismiss: (() -> Void)?) {
        self.dismiss = dismiss
        _zimFiles = FetchRequest(
            sortDescriptors: [Defaults[.opneZIMsSorting].sortDescriptor()],
            predicate: ZimFile.openedPredicate(showBy: Defaults[.openZIMsShowBy]),
            animation: .easeInOut
        )
    }
    
    var body: some View {
        NavigationStack(path: $navPath) {
            LazyVGrid(
                columns: ([GridItem(.adaptive(minimum: 250, maximum: 500), spacing: 12)]),
                alignment: .leading,
                spacing: 12
            ) {
                ForEach(zimFiles, id: \.fileID) { zimFile in
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
                Message(text: showBy.noResultsMessage)
            }
        }
        .toolbar {
            ZimFilters(sortBy: $sortBy, showBy: $showBy)
            ToolbarItem(placement: .topBarTrailing) {
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
        .onChange(of: zimFiles.count) {
            if let fileIdToOpen,
               let selectedZimFile = zimFiles.first(where: { $0.fileID == fileIdToOpen }) {
                self.fileIdToOpen = nil
                navPath = [selectedZimFile]
            }
        }
    }
}

#endif
