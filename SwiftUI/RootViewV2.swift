//
//  RootViewV2.swift
//  Kiwix
//
//  Created by Chris Li on 10/8/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

@available(macOS 12.0, iOS 16.0, *)
struct RootViewV2: View {
    @Binding var url: URL?
    @EnvironmentObject private var viewModel: ViewModel
    
    private let primaryNavigationItems: [NavigationItem] = [.reading, .bookmarks]
    private let libraryNavigationItems: [NavigationItem] = [.opened, .categories, .downloads, .new]
    
    var body: some View {
        #if os(macOS)
        NavigationView {
            sidebar
            detail.frame(minWidth: 500, minHeight: 500)
        }
        #elseif os(iOS)
        NavigationSplitView {
            sidebar
        } detail: {
            NavigationStack {
                detail.navigationBarTitleDisplayMode(.inline)
            }
        }
        #endif
    }
    
    @ViewBuilder
    private func navigationItem(_ navigationItem: NavigationItem) -> some View {
        #if os(macOS)
        Label(navigationItem.name, systemImage: navigationItem.icon)
        #elseif os(iOS)
        NavigationLink(value: navigationItem) {
            Label(navigationItem.name, systemImage: navigationItem.icon)
        }
        #endif
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
        .toolbar { SettingsButton() }
        #endif
    }
    
    @ViewBuilder
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
