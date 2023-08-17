//
//  Library.swift
//  Kiwix
//
//  Created by Chris Li on 4/23/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

#if os(iOS)
/// Tabbed library view on iOS & iPadOS
struct Library: View {
    @EnvironmentObject private var viewModel: LibraryViewModel
    
    var body: some View {
        TabView(selection: $viewModel.selectedTabItem) {
            ForEach(LibraryTabItem.allCases) { tabItem in
                SheetContent {
                    switch tabItem {
                    case .opened:
                        ZimFilesOpened()
                    case .categories:
                        List(Category.allCases) { category in
                            NavigationLink {
                                ZimFilesCategory(category: .constant(category))
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
                    case .downloads:
                        ZimFilesDownloads()
                    case .new:
                        ZimFilesNew()
                    }
                }
                .tag(tabItem)
                .tabItem { Label(tabItem.name, systemImage: tabItem.icon) }
            }
        }.onAppear {
            viewModel.start(isUserInitiated: false)
        }.onChange(of: viewModel.selectedTabItem) { _ in
            viewModel.selectedZimFile = nil
        }
    }
}

@available(iOS 16.0, *)
struct Library_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            Library()
                .environmentObject(LibraryViewModel())
                .environment(\.managedObjectContext, Database.viewContext)
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
                        ZimFileDetail(zimFile: zimFile)
                    } else {
                        Message(text: "Select a zim file to see detail").background(.thickMaterial)
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
    
    let zimFile: ZimFile
    
    func body(content: Content) -> some View {
        Group {
            #if os(macOS)
            Button {
                viewModel.selectedZimFile = zimFile
            } label: {
                content
            }.buttonStyle(.plain)
            #elseif os(iOS)
            NavigationLink(tag: zimFile, selection: $viewModel.selectedZimFile) {
                ZimFileDetail(zimFile: zimFile)
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
        Button {
            guard let url = ZimFileService.shared.getMainPageURL(zimFileID: zimFile.fileID) else { return }
            NotificationCenter.default.post(name: Notification.Name.openURL, object: nil, userInfo: ["url": url])
        } label: {
            Label("Main Page", systemImage: "house")
        }
        Button {
            guard let url = ZimFileService.shared.getRandomPageURL(zimFileID: zimFile.fileID) else { return }
            NotificationCenter.default.post(name: Notification.Name.openURL, object: nil, userInfo: ["url": url])
        } label: {
            Label("Random Page", systemImage: "die.face.5")
        }
    }
    
    @ViewBuilder
    var supplementaryActions: some View {
        Button {
            viewModel.selectedZimFile = zimFile
        } label: {
            Label("Show Detail", systemImage: "info.circle")
        }
        if let downloadURL = zimFile.downloadURL {
            Button {
                #if os(macOS)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(downloadURL.absoluteString, forType: .URL)
                #elseif os(iOS)
                UIPasteboard.general.setValue(downloadURL.absoluteString, forPasteboardType: UTType.url.identifier)
                #endif
            } label: {
                Label("Copy URL", systemImage: "doc.on.doc")
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
            Label("Copy ID", systemImage: "barcode.viewfinder")
        }
    }
}
