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
import Defaults

/// A grid of zim files that are newly available.
struct ZimFilesNew: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject var viewModel: LibraryViewModel
    @Default(.libraryLanguageCodes) private var languageCodes
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \ZimFile.created, ascending: false),
            NSSortDescriptor(keyPath: \ZimFile.name, ascending: true),
            NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)
        ],
        animation: .easeInOut
    ) private var zimFiles: FetchedResults<ZimFile>
    @State private var searchText = ""
    private var filterPredicate: NSPredicate {
        ZimFilesNew.buildPredicate(searchText: searchText)
    }
    let dismiss: (() -> Void)? // iOS only

    var body: some View {
        LazyVGrid(
            columns: ([GridItem(.adaptive(minimum: 250, maximum: 500), spacing: 12)]),
            alignment: .leading,
            spacing: 12
        ) {
            ForEach(zimFiles.filter { filterPredicate.evaluate(with: $0) }, id: \.fileID) { zimFile in
                Group {
                #if os(macOS)
                    Button {
                        viewModel.selectedZimFile = zimFile
                    } label: {
                        ZimFileCell(zimFile, prominent: .name)
                    }.buttonStyle(.plain)
                #elseif os(iOS)
                    NavigationLink {
                        ZimFileDetail(zimFile: zimFile, dismissParent: dismiss)
                    } label: {
                        ZimFileCell(zimFile, prominent: .name)
                    }
                #endif
                }.contextMenu {
                    if zimFile.fileURLBookmark != nil, !zimFile.isMissing {
                        Section { ArticleActions(zimFileID: zimFile.fileID) }
                    }
                    if let downloadURL = zimFile.downloadURL {
                        Section { CopyPasteMenu(downloadURL: downloadURL) }
                    }
                }
            }
        }
        .modifier(GridCommon())
        .modifier(ToolbarRoleBrowser())
        .navigationTitle(NavigationItem.new.name)
        .searchable(text: $searchText)
        .onAppear {
            viewModel.start(isUserInitiated: false)
        }
        .overlay {
            if zimFiles.isEmpty {
                switch viewModel.state {
                case .inProgress:
                    Message(text: LocalString.zim_file_catalog_fetching_message)
                case .error:
                    Message(text: LocalString.library_refresh_error_retrieve_description, color: .red)
                case .initial, .complete:
                    Message(text: LocalString.zim_file_new_overlay_empty)
                }
            }
        }
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarLeading) {
                if #unavailable(iOS 16), horizontalSizeClass == .regular {
                    Button {
                        NotificationCenter.toggleSidebar()
                    } label: {
                        Label(LocalString.zim_file_opened_toolbar_show_sidebar_label,
                              systemImage: "sidebar.left")
                    }
                }
            }
            #endif
            ToolbarItem {
                if viewModel.state == .inProgress {
                    ProgressView()
                    #if os(macOS)
                        .scaleEffect(0.5)
                    #endif
                } else {
                    Button {
                        viewModel.start(isUserInitiated: true)
                    } label: {
                        Label(LocalString.zim_file_new_button_refresh,
                              systemImage: "arrow.triangle.2.circlepath.circle")
                    }
                }
            }
        }
    }

    private static func buildPredicate(searchText: String) -> NSPredicate {
        var predicates = [
            NSPredicate(format: "languageCode IN %@", Defaults[.libraryLanguageCodes]),
            NSPredicate(format: "requiresServiceWorkers == false")
        ]
        if let aMonthAgo = Calendar.current.date(byAdding: .month, value: -3, to: Date()) {
            predicates.append(NSPredicate(format: "created > %@", aMonthAgo as CVarArg))
        }
        if !searchText.isEmpty {
            predicates.append(
                NSCompoundPredicate(orPredicateWithSubpredicates: [
                    NSPredicate(format: "name CONTAINS[cd] %@", searchText),
                    NSPredicate(format: "fileDescription CONTAINS[cd] %@", searchText)
                ])
            )
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}

@available(macOS 13.0, iOS 16.0, *)
struct ZimFilesNew_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ZimFilesNew(dismiss: nil)
                .environmentObject(LibraryViewModel())
                .environment(\.managedObjectContext, Database.shared.viewContext)
        }
    }
}
