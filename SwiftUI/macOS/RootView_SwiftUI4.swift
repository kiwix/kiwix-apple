//
//  RootView_SwiftUI4.swift
//  Kiwix
//
//  Created by Chris Li on 8/5/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

import Introspect

@available(macOS 13.0, iOS 16.0, *)
struct RootView_SwiftUI4: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var navigationItem: NavigationItem? = .reading
    @State private var url: URL?
    @State private var searchText = ""
    @StateObject private var readingViewModel = ReadingViewModel()
    
    private let primaryNavigationItems: [NavigationItem] = [.reading, .bookmarks, .map]
    private let libraryNavigationItems: [NavigationItem] = [.opened, .categories, .new, .downloads]
    
    var body: some View {
        if horizontalSizeClass == .regular {
            NavigationSplitView {
                List(selection: $navigationItem) {
                    ForEach(primaryNavigationItems, id: \.self) { navigationLink($0) }
                    Section {
                        ForEach(primaryNavigationItems, id: \.self) { navigationLink($0) }
                    } header: { Text("Library") }
                }
            } detail: {
                switch navigationItem {
                case .reading:
                    ReadingView(url: $url)
                        .searchable(text: $searchText)
                        .environmentObject(readingViewModel)
                case .bookmarks:
                    Bookmarks(url: $url)
                case .map:
                    MapView()
                case .opened:
                    ZimFilesOpened()
                case .categories:
                    Text(navigationItem?.name ?? "")
                case .new:
                    Text(navigationItem?.name ?? "")
                case .downloads:
                    Text(navigationItem?.name ?? "")
                default:
                    EmptyView()
                }
            }
            .environment(\.managedObjectContext, Database.shared.container.viewContext)
        } else {
            Text("Hello, World!")
        }
    }
    
    @ViewBuilder
    private func navigationLink(_ navigationItem: NavigationItem) -> some View {
        NavigationLink(value: navigationItem) {
            Label(navigationItem.name, systemImage: navigationItem.icon)
        }
    }
}

enum NavigationItem: String, Identifiable, CaseIterable {
    var id: String { rawValue }

    case reading, bookmarks, map, opened, categories, new, downloads, settings

    var name: String {
        switch self {
        case .reading:
            return "Reading"
        case .bookmarks:
            return "Bookmarks"
        case .map:
            return "Map"
        case .settings:
            return "Settings"
        case .opened:
            return "Opened"
        case .categories:
            return "Categories"
        case .new:
            return "New"
        case .downloads:
            return "Downloads"
        }
    }
    
    var icon: String {
        switch self {
        case .reading:
            return "book"
        case .bookmarks:
            return "star"
        case .map:
            return "map"
        case .settings:
            return "gear"
        case .opened:
            return "folder"
        case .categories:
            return "books.vertical"
        case .new:
            return "newspaper"
        case .downloads:
            return "tray.and.arrow.down"
        }
    }
}
