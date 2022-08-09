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
                splitView_SwiftUI4
            } else {
                #if os(macOS)
                splitView_SwiftUI3
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
    
    @available(macOS 13.0, iOS 16.0, *)
    private var splitView_SwiftUI4: some View {
        NavigationSplitView {
            List(selection: $navigationItem) {
                ForEach(primaryNavigationItems, id: \.self) { navigationLink($0) }
                Section {
                    ForEach(libraryNavigationItems, id: \.self) { navigationLink($0) }
                } header: { Text("Library") }
            }.navigationTitle("Kiwix")
        } detail: { detail }
    }
    
    @available(macOS 12.0, iOS 16.0, *)
    private var splitView_SwiftUI3: some View {
        NavigationView {
            List(selection: $navigationItem) {
                ForEach(primaryNavigationItems, id: \.self) { navigationItem in
                    Label(navigationItem.name, systemImage: navigationItem.icon)
                }
                Section {
                    ForEach(libraryNavigationItems, id: \.self) { navigationItem in
                        Label(navigationItem.name, systemImage: navigationItem.icon)
                    }
                } header: { Text("Library") }
            }
            .frame(minWidth: 150)
            .toolbar {
                #if os(macOS)
                SidebarButton()
                #endif
            }
            detail
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
    
    @ViewBuilder
    @available(macOS 13.0, iOS 16.0, *)
    private func navigationLink(_ navigationItem: NavigationItem) -> some View {
        NavigationLink(value: navigationItem) {
            Label(navigationItem.name, systemImage: navigationItem.icon)
        }
    }
}
