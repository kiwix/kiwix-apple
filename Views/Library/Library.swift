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
    @EnvironmentObject private var navigation: NavigationViewModel
    @State private var tabItem: LibraryTabItem
    @Default(.hasSeenCategories) private var hasSeenCategories
    private let categories: [Category]
    let dismiss: (() -> Void)?

    init(
        dismiss: (() -> Void)?,
        tabItem: LibraryTabItem = .categories,
        categories: [Category] = CategoriesToLanguages().allCategories()
    ) {
        self.dismiss = dismiss
        self.tabItem = tabItem
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
                        .navigationTitle(MenuItem.categories.name)
                    case .opened:
                        ZimFilesOpened(dismiss: dismiss)
                    case .downloads:
                        ZimFilesDownloads(dismiss: dismiss)
                            .environment(\.managedObjectContext, Database.shared.viewContext)
                    case .new:
                        ZimFilesNew(dismiss: dismiss)
                    case .hotspot:
                        HotspotZimFilesSelection()
                    }
                }
                .tag(tabItem)
                .tabItem { Label(tabItem.name, systemImage: tabItem.icon) }
            }
        }.onAppear {
            viewModel.start(isUserInitiated: false)
        }.onDisappear {
            hasSeenCategories = true
        }.onReceive(navigation.showDownloads) { _ in
            if tabItem != .downloads {
                tabItem = .downloads
            }
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

/// Multi ZIM files unlinking side panel
struct MultiZimFilesDetail: View {
    let zimFiles: Set<ZimFile>
    @State private var isPresentingUnlinkAlert: Bool = false
    
    private func zimFilesCount() -> String {
        Formatter.number.string(from: NSNumber(value: zimFiles.count)) ?? ""
    }
    
    var body: some View {
        List {
            Section(LocalString.multi_zim_files_selected_sidebar_title) {
                Attribute(
                    title: LocalString.multi_zim_files_selected_description_count,
                    detail: zimFilesCount()
                )
            }.collapsible(false)
            Section(LocalString.zim_file_list_actions_text) {
                Action(title: LocalString.zim_file_action_unlink_title, isDestructive: true) {
                    isPresentingUnlinkAlert = true
                }.alert(isPresented: $isPresentingUnlinkAlert) {
                    Alert(
                        title: Text(LocalString.zim_file_action_unlink_multi_title(withArgs: zimFilesCount())),
                        message: Text(LocalString.zim_file_action_unlink_multi_message(withArgs: zimFilesCount())),
                        primaryButton: .destructive(Text(LocalString.zim_file_action_unlink_button_title)) {
                            Task {
                                for zimFile in zimFiles {
                                    await LibraryOperations.unlink(zimFileID: zimFile.fileID)
                                }
                            }
                        },
                        secondaryButton: .cancel()
                    )
                }
            }.collapsible(false)
        }.listStyle(.sidebar)
    }
}

struct DetailSidePanel<Content: View>: View {
    @StateObject private var selection = SelectedZimFileViewModel()
    private let contentView: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        contentView = content
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            contentView().safeAreaInset(edge: .trailing, spacing: 0) {
                HStack(spacing: 0) {
                    Divider()
                    if let zimFile = selection.selectedZimFile {
                        ZimFileDetail(zimFile: zimFile, dismissParent: nil)
                    } else {
                        Message(text: LocalString.library_zim_file_details_side_panel_message)
                            .background(.thickMaterial)
                    }
                }.frame(width: 275).background(.ultraThinMaterial)
            }
        }
        // !important, otherwise the wrapped contentView
        // won't get the selection dependency
        .environmentObject(selection)
    }
}

/// A macOS only variant of LibraryZimFileContext
/// supporting multiple selection with command click
/// and single selection with pure click
struct MultiZimFilesContext<Content: View>: View {
    @ObservedObject var selection: MultiSelectedZimFilesViewModel
    
    private let content: Content
    private let zimFile: ZimFile
    
    init(
        @ViewBuilder content: () -> Content,
        zimFile: ZimFile,
        selection: MultiSelectedZimFilesViewModel
    ) {
        self.content = content()
        self.zimFile = zimFile
        self.selection = selection
    }
    
    var body: some View {
        Group {
            content
                .gesture(TapGesture().modifiers(.command).onEnded({ _ in
                    selection.toggleMultiSelect(of: zimFile)
                }))
                .gesture(TapGesture().onEnded({ _ in
                    selection.singleSelect(zimFile: zimFile)
                }))
        }.contextMenu {
            ZimFileContextMenu(zimFile: zimFile)
        }
    }
}
#endif

/// Cross platform, only multi-selection is supported
struct MultiZimFilesSelectionContext<Content: View>: View {
    @ObservedObject var selection: MultiSelectedZimFilesViewModel
    
    private let content: Content
    private let zimFile: ZimFile
    
    init(
        @ViewBuilder content: () -> Content,
        zimFile: ZimFile,
        selection: MultiSelectedZimFilesViewModel
    ) {
        self.content = content()
        self.zimFile = zimFile
        self.selection = selection
    }
    
    var body: some View {
        Group {
            content
                .onTapGesture(perform: {
                    selection.toggleMultiSelect(of: zimFile)
                })
        }.contextMenu {
            ZimFileContextMenu(zimFile: zimFile)
        }
    }
}

/// On macOS, makes the content view clickable, to select a single ZIM file
/// On iOS, converts the modified view to a NavigationLink that goes to the zim file detail.
struct LibraryZimFileContext<Content: View>: View {
    @ObservedObject var selection: SelectedZimFileViewModel
    private let content: Content
    private let zimFile: ZimFile
    /// iOS only
    private let dismiss: (() -> Void)?
    
    init(
        @ViewBuilder content: () -> Content,
        zimFile: ZimFile,
        selection: SelectedZimFileViewModel,
        dismiss: (() -> Void)? = nil
    ) {
        self.content = content()
        self.zimFile = zimFile
        self.selection = selection
        self.dismiss = dismiss
    }
    
    var body: some View {
        Group {
#if os(macOS)
            content.onTapGesture {
                selection.selectedZimFile = zimFile
            }
#elseif os(iOS)
            NavigationLink {
                ZimFileDetail(zimFile: zimFile, dismissParent: dismiss)
            } label: {
                content
            } .accessibilityIdentifier(zimFile.name)
#endif
        }.contextMenu {
            ZimFileContextMenu(zimFile: zimFile)
        }
    }
}
