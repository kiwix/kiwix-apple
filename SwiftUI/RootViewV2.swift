//
//  RootViewV2.swift
//  Kiwix
//
//  Created by Chris Li on 10/8/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

import Introspect

@available(macOS 12.0, iOS 16.0, *)
struct RootViewV2: View {
    @Binding var url: URL?
    @EnvironmentObject private var viewModel: ViewModel
    @StateObject private var readingViewModel = ReadingViewModel()
    
    private let primaryNavigationItems: [NavigationItem] =
        FeatureFlags.map ? [.reading, .bookmarks, .map(location: nil)] : [.reading, .bookmarks]
    private let libraryNavigationItems: [NavigationItem] = [.opened, .categories, .downloads, .new]
    
    var body: some View {
//        if #available(macOS 13.0, *) {
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
//        } else {
            NavigationView {
                sidebar
                detail.frame(minWidth: 500, minHeight: 500)
            }
            .navigationViewStyle(.columns)
            .onChange(of: url) { _ in
                viewModel.navigationItem = .reading
            }
//        }
    }
    
    @ViewBuilder
    private func navigationItem(_ navigationItem: NavigationItem) -> some View {
//        if #available(macOS 13.0, *) {
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
        .toolbar { SettingsButton() }
        #endif
    }
    
    @ViewBuilder
    private var detail: some View {
        switch viewModel.navigationItem {
        case .reading:
            ReadingView(url: $url).environmentObject(readingViewModel)
        case .bookmarks:
            BookmarksView(url: $url)
        case .map(let location):
            Map(location: location)
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
