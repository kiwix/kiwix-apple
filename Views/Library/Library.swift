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

/// On macOS, adds a panel to the right of the modified view to show zim file detail.
struct LibraryZimFileMultiSelectDetailSidePanel: ViewModifier {
    @ObservedObject var viewModel: LibraryMultiSelectViewModel
    @State private var isPresentingUnlinkAlert: Bool = false

    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            Divider()
            content.safeAreaInset(edge: .trailing, spacing: 0) {
                HStack(spacing: 0) {
                    Divider()
                    switch viewModel.selectedZimFiles.count {
                    case 0:
                        Message(text: LocalString.library_zim_file_details_side_panel_message)
                            .background(.thickMaterial)
                    case 1:
                        ZimFileDetail(zimFile: viewModel.selectedZimFiles.first!, dismissParent: nil)
                    default:
                        Action(title: LocalString.zim_file_action_unlink_title, isDestructive: true) {
                            isPresentingUnlinkAlert = true
                        }.alert(isPresented: $isPresentingUnlinkAlert) {
                            Alert(
                                title: Text(LocalString.zim_file_action_unlink_title + " " + "\(viewModel.selectedZimFiles.count)"),
                                message: Text(LocalString.zim_file_action_unlink_message),
                                primaryButton: .destructive(Text(LocalString.zim_file_action_unlink_button_title)) {
                                    Task {
                                        for zimFile in viewModel.selectedZimFiles {
                                            await LibraryOperations.unlink(zimFileID: zimFile.fileID)
                                        }
                                    }
                                },
                                secondaryButton: .cancel()
                            )
                        }
                    }
                }.frame(width: 275).background(.ultraThinMaterial)
            }
        }.onAppear { viewModel.resetSelection() }
    }
}


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
struct LibraryZimFileContext<Content: View>: View {
    @EnvironmentObject private var viewModel: LibraryViewModel
    
    private let content: Content
    private let zimFile: ZimFile
    /// iOS only
    private let dismiss: (() -> Void)?
    /// macOS only
    private let onMultiSelected: ((Bool) -> Void)?
    
    init(
        @ViewBuilder content: () -> Content,
        zimFile: ZimFile,
        onMultiSelected: ((Bool) -> Void)? = nil,
        dismiss: (() -> Void)? = nil
    ) {
        self.content = content()
        self.zimFile = zimFile
        self.onMultiSelected = onMultiSelected
        self.dismiss = dismiss
    }
    
    var body: some View {
        Group {
#if os(macOS)
            if let onMultiSelected {
                content
                    .gesture(TapGesture().modifiers(.command).onEnded({ value in
                        onMultiSelected(true)
                    }))
                    .gesture(TapGesture().onEnded({ _ in
                        onMultiSelected(false)
                    }))
            } else {
                content.onTapGesture {
                    viewModel.selectedZimFile = zimFile
                }
            }
#elseif os(iOS)
            NavigationLink {
                ZimFileDetail(zimFile: zimFile, dismissParent: dismiss)
            } label: {
                content
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
