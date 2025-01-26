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
import Defaults

#if os(iOS)
/// Tabbed library view on iOS & iPadOS
struct Library: View {
    @EnvironmentObject private var viewModel: LibraryViewModel
    @SceneStorage("LibraryTabItem") private var tabItem: LibraryTabItem = .categories
    @Default(.hasSeenCategories) private var hasSeenCategories
    private let categories: [Category]
    let dismiss: (() -> Void)?

    init(
        dismiss: (() -> Void)?,
        categories: [Category] = CategoriesToLanguages().allCategories()
    ) {
        self.dismiss = dismiss
        self.categories = categories
    }

    var body: some View {
        TabView(selection: $tabItem) {
            ForEach(LibraryTabItem.allCases) { tabItem in
                SheetContent {
                    switch tabItem {
                    case .categories:
                        List(categories) { category in
                            NavigationLink {
                                ZimFilesCategory(category: .constant(category), dismiss: dismiss)
                                    .navigationTitle(category.name)
                                    .navigationBarTitleDisplayMode(.inline)
                            } label: {
                                HStack {
                                    Favicon(category: category).frame(height: 26)
                                    Text(category.name)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .navigationTitle(NavigationItem.categories.name)
                    case .opened:
                        ZimFilesOpened(dismiss: dismiss)
                    case .downloads:
                        ZimFilesDownloads(dismiss: dismiss)
                            .environment(\.managedObjectContext, Database.shared.viewContext)
                    case .new:
                        ZimFilesNew(dismiss: dismiss)
                    }
                }
                .tag(tabItem)
                .tabItem { Label(tabItem.name, systemImage: tabItem.icon) }
            }
        }.onAppear {
            viewModel.start(isUserInitiated: false)
        }.onDisappear {
            hasSeenCategories = true
        }
    }
}

@available(iOS 16.0, *)
struct Library_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            Library(dismiss: nil)
                .environmentObject(LibraryViewModel())
                .environment(\.managedObjectContext, Database.shared.viewContext)
        }
    }
}

#elseif os(macOS)

/// On macOS, adds a panel to the right of the modified view to show zim file detail.
struct LibraryZimFileDetailSidePanel: ViewModifier {
    @EnvironmentObject private var viewModel: LibraryViewModel

    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            Divider()
            content.safeAreaInset(edge: .trailing, spacing: 0) {
                HStack(spacing: 0) {
                    Divider()
                    if let zimFile = viewModel.selectedZimFile {
                        ZimFileDetail(zimFile: zimFile, dismissParent: nil)
                    } else {
                        Message(text: LocalString.library_zim_file_details_side_panel_message)
                            .background(.thickMaterial)
                    }
                }.frame(width: 275).background(.ultraThinMaterial)
            }
        }.onAppear { viewModel.selectedZimFile = nil }
    }
}
#endif

/// On macOS, converts the modified view to a Button that modifies the currently selected zim file
/// On iOS, converts the modified view to a NavigationLink that goes to the zim file detail.
struct LibraryZimFileContext: ViewModifier {
    @EnvironmentObject private var viewModel: LibraryViewModel
    @EnvironmentObject private var navigation: NavigationViewModel

    let zimFile: ZimFile
    let dismiss: (() -> Void)? // iOS only

    init(zimFile: ZimFile, dismiss: (() -> Void)?) {
        self.zimFile = zimFile
        self.dismiss = dismiss
    }

    func body(content: Content) -> some View {
        Group {
            #if os(macOS)
            Button {
                viewModel.selectedZimFile = zimFile
            } label: {
                content
            }.buttonStyle(.plain)
            #elseif os(iOS)
            NavigationLink {
                ZimFileDetail(zimFile: zimFile, dismissParent: dismiss)
            } label: {
                content
            }
            #endif
        }.contextMenu {
            if zimFile.fileURLBookmark != nil, !zimFile.isMissing {
                Section { articleActions }
            }
            Section { supplementaryActions }
        }
    }

    @ViewBuilder
    var articleActions: some View {
        AsyncButton {
            guard let url = await ZimFileService.shared.getMainPageURL(zimFileID: zimFile.fileID) else { return }
            NotificationCenter.openURL(url, inNewTab: true)
        } label: {
            Label(LocalString.library_zim_file_context_main_page_label, systemImage: "house")
        }
        AsyncButton {
            guard let url = await ZimFileService.shared.getRandomPageURL(zimFileID: zimFile.fileID) else { return }
            NotificationCenter.openURL(url, inNewTab: true)
        } label: {
            Label(LocalString.library_zim_file_context_random_label, systemImage: "die.face.5")
        }
    }

    @ViewBuilder
    var supplementaryActions: some View {
        if let downloadURL = zimFile.downloadURL {
            Button {
                #if os(macOS)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(downloadURL.absoluteString, forType: .URL)
                #elseif os(iOS)
                UIPasteboard.general.setValue(downloadURL.absoluteString, forPasteboardType: UTType.url.identifier)
                #endif
            } label: {
                Label(LocalString.library_zim_file_context_copy_url, systemImage: "doc.on.doc")
            }
        }
        Button {
            #if os(macOS)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(zimFile.fileID.uuidString, forType: .string)
            #elseif os(iOS)
            UIPasteboard.general.setValue(zimFile.fileID.uuidString, forPasteboardType: UTType.plainText.identifier)
            #endif
        } label: {
            Label(LocalString.library_zim_file_context_copy_id, systemImage: "barcode.viewfinder")
        }
    }
}
