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
    @State private var isFileImporterPresented = false
    @State private var navigationItem: NavigationItem? = .reading
    @State private var url: URL?
    @State private var searchText = ""
    @StateObject private var readingViewModel = ReadingViewModel()
    
    private let primaryNavigationItems: [NavigationItem] = [.reading, .bookmarks, .map]
    private let libraryNavigationItems: [NavigationItem] = [.opened, .categories, .new, .downloads]
    
    var body: some View {
        Group {
            if horizontalSizeClass == .regular, #available(macOS 13.0, iOS 16.0, *) {
                NavigationSplitView {
                    sidebar
                } detail: {
                    detail
                }
            } else {
                #if os(macOS)
                NavigationView {
                    sidebar
                    detail
                }
                #elseif os(iOS)
                RootView_iOS()
                #endif
            }
        }
        .environment(\.managedObjectContext, Database.shared.container.viewContext)
        .onChange(of: url) { _ in
            navigationItem = .reading
        }
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
        .toolbar {
            #if os(macOS)
            SidebarButton()
            #endif
        }
    }
    
    @ViewBuilder
    @available(macOS 12.0, iOS 16.0, *)
    private var detail: some View {
        switch navigationItem {
        case .reading:
            ReadingView(url: $url).searchable(text: $searchText).environmentObject(readingViewModel)
        case .bookmarks:
            BookmarksView(url: $url)
        case .map:
            MapView()
        case .opened:
            ZimFilesOpened(isFileImporterPresented: $isFileImporterPresented)
        case .categories:
            LibraryCategories()
        case .new:
            ZimFilesNew()
        case .downloads:
            ZimFilesDownloads()
        default:
            EmptyView()
        }
    }
}
