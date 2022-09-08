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
    @State private var url: URL?
    @StateObject private var viewModel = ViewModel()
    @StateObject private var readingViewModel = ReadingViewModel()
    
    private let primaryNavigationItems: [NavigationItem] = [.reading, .bookmarks]
    private let libraryNavigationItems: [NavigationItem] = [.opened, .categories, .downloads, .new]
    
    var body: some View {
        Group {
// macOS 13 & iPadOS 16 & iOS 16, horizontal regular
//            NavigationSplitView {
//                sidebar
//            } detail: {
//                NavigationStack {
//                    detail
//                    #if os(iOS)
//                        .navigationBarTitleDisplayMode(.inline)
//                    #endif
//                }
//            }
            
            #if os(macOS)
            NavigationView {
                sidebar
                detail.frame(minWidth: 500, minHeight: 500)
            }
            #elseif os(iOS)
            RootView_iOS(url: $url).ignoresSafeArea(.all)
            #endif
        }
        .modifier(ActiveSheet_iOS(url: $url))
        .modifier(FocusedSceneValue(\.navigationItem, $viewModel.navigationItem))
        .modifier(FocusedSceneValue(\.url, url))
        .onChange(of: url) { _ in
            viewModel.navigationItem = .reading
            viewModel.activeSheet = nil
        }
        .onChange(of: horizontalSizeClass) { _ in
            viewModel.navigationItem = .reading
            viewModel.activeSheet = nil
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
        .environmentObject(viewModel)
        .environmentObject(readingViewModel)
    }
    
    @ViewBuilder
    private func navigationItem(_ navigationItem: NavigationItem) -> some View {
//        if #available(macOS 13.0, iOS 16.0, *) {
//            NavigationLink(value: navigationItem) {
//                Label(navigationItem.name, systemImage: navigationItem.icon)
//            }
//        } else {
            Label(navigationItem.name, systemImage: navigationItem.icon)
//        }
    }
    
    @ViewBuilder
    private var sidebar: some View {
        List(selection: $viewModel.navigationItem) {
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
                viewModel.activeSheet = .settings
            } label: { Image(systemName: "gear") }
        }
        #endif
    }
    
    @ViewBuilder
    @available(macOS 12.0, iOS 16.0, *)
    private var detail: some View {
        switch viewModel.navigationItem {
        case .reading:
            ReadingView(url: $url)
        case .bookmarks:
            BookmarksView(url: $url)
        case .map:
            MapView()
        case .opened:
            ZimFilesOpened(url: $url)
        case .categories:
            ZimFilesCategories(url: $url)
        case .downloads:
            ZimFilesDownloads(url: $url)
        case .new:
            ZimFilesNew(url: $url)
        case .none:
            EmptyView()
        }
    }
}

struct ActiveSheet_iOS: ViewModifier {
    @Binding var url: URL?
    @EnvironmentObject var viewModel: ViewModel
    
    func body(content: Content) -> some View {
        #if os(iOS)
        content.sheet(item: $viewModel.activeSheet) { activeSheet in
            switch activeSheet {
            case .outline:
                SheetView {
                    OutlineTree().listStyle(.plain).navigationBarTitleDisplayMode(.inline)
                }
            case .bookmarks:
                SheetView { BookmarksView(url: $url) }
            case .library:
                LibraryView_iOS(url: $url)
            case .settings:
                SheetView { SettingsView() }
            }
        }
        #elseif os(macOS)
        content
        #endif
    }
}
