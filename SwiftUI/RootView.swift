//
//  RootView.swift
//  Kiwix
//
//  Created by Chris Li on 8/5/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct RootView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var isShowingSetting = false
    @State private var navigationItem: NavigationItem? = .reading
    @State private var url: URL?
    @StateObject private var readingViewModel = ReadingViewModel()
    
    private let primaryNavigationItems: [NavigationItem] = [.reading, .bookmarks]
    private let libraryNavigationItems: [NavigationItem] = [.opened, .categories, .downloads, .new]
    
    var body: some View {
        Group {
            if #available(macOS 13.0, iOS 16.0, *) {  // macOS 13 & iPadOS 16 & iOS 16
                if horizontalSizeClass == .regular {
                    NavigationSplitView {
                        sidebar
                    } detail: {
                        NavigationStack {
                            detail
                            #if os(iOS)
                                .navigationBarTitleDisplayMode(.inline)
                            #endif
                        }
                    }.focusedSceneValue(\.navigationItem, $navigationItem)
                } else {
                    NavigationStack {
                        ReadingView(url: $url).environmentObject(readingViewModel)
                    }
                }
            } else {
                #if os(macOS) // macOS 12
                NavigationView {
                    sidebar
                    detail.frame(minWidth: 500, minHeight: 500)
                }.focusedSceneValue(\.navigationItem, $navigationItem)
                #elseif os(iOS)  // iPadOS&iOS 14&15
                RootView_iOS(url: $url).ignoresSafeArea(.container).environmentObject(readingViewModel)
                #endif
            }
        }
        .environment(\.managedObjectContext, Database.shared.container.viewContext)
        .modifier(FocusedSceneValue(\.url, url))
        .onChange(of: url) { _ in
            navigationItem = .reading
            readingViewModel.activeSheet = nil
        }
        .onChange(of: horizontalSizeClass) { _ in
            navigationItem = .reading
            readingViewModel.activeSheet = nil
        }
        .onOpenURL { url in
            if url.isFileURL {
                guard let metadata = ZimFileService.getMetaData(url: url) else { return }
                LibraryViewModel.open(url: url)
                self.url = ZimFileService.shared.getMainPageURL(zimFileID: metadata.fileID)
            } else if url.scheme == "kiwix" {
                self.url = url
            }
        }
        #if os(iOS)
        .sheet(item: $readingViewModel.activeSheet) { activeSheet in
            switch activeSheet {
            case .outline:
                SheetView {
                    OutlineTree().listStyle(.plain).navigationBarTitleDisplayMode(.inline)
                }.modifier(OutlineDetents_SwiftUI4())
            case .bookmarks:
                SheetView { BookmarksView(url: $url) }
            case .library:
                LibraryView_iOS()
            case .settings:
                SheetView { SettingsView() }
            }
        }
        #endif
    }
    
    @ViewBuilder
    private func navigationItem(_ navigationItem: NavigationItem) -> some View {
        if #available(macOS 13.0, iOS 16.0, *) {
            NavigationLink(value: navigationItem) {
                Label(navigationItem.name, systemImage: navigationItem.icon)
            }
        } else {
            Label(navigationItem.name, systemImage: navigationItem.icon)
        }
    }
    
    @ViewBuilder
    private var sidebar: some View {
        List(selection: $navigationItem) {
            ForEach(primaryNavigationItems, id: \.self) { navigationItem($0) }
            Section {
                ForEach(libraryNavigationItems, id: \.self) { navigationItem($0) }
            } header: { Text("Library") }
        }
        .navigationTitle("Kiwix")
        .frame(minWidth: 150)
        #if os(macOS)
        .toolbar { SidebarButton() }
        #elseif os(iOS)
        .toolbar {
            Button {
                readingViewModel.activeSheet = .settings
            } label: { Image(systemName: "gear") }
        }
        #endif
    }
    
    @ViewBuilder
    @available(macOS 12.0, iOS 16.0, *)
    private var detail: some View {
        switch navigationItem {
        case .reading:
            ReadingView(url: $url).environmentObject(readingViewModel)
        case .bookmarks:
            BookmarksView(url: $url)
        case .map:
            MapView()
        case .opened:
            ZimFilesOpened()
        case .categories:
            ZimFilesCategories()
        case .downloads:
            ZimFilesDownloads()
        case .new:
            ZimFilesNew()
        case .none:
            EmptyView()
        }
    }
}
