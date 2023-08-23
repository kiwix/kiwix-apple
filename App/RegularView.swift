//
//  RegularView.swift
//  Kiwix
//
//  Created by Chris Li on 7/1/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import SwiftUI

import SwiftUIIntrospect

#if os(iOS)
@available(iOS 16.0, *)
struct RegularView: View {
    @EnvironmentObject private var navigation: NavigationViewModel
    @State private var path = NavigationPath()
    
    private let primaryItems: [NavigationItem] = [.bookmarks, .settings]
    private let libraryItems: [NavigationItem] = [.opened, .categories, .downloads, .new]
    
    var body: some View {
        NavigationSplitView {
            List(selection: $navigation.currentItem) {
                ForEach(primaryItems, id: \.self) { navigationItem in
                    Label(navigationItem.name, systemImage: navigationItem.icon)
                }
                Section("Tabs") {
                    TabsSectionContent()
                }
                Section("Library") {
                    ForEach(libraryItems, id: \.self) { navigationItem in
                        Label(navigationItem.name, systemImage: navigationItem.icon)
                    }
                }
            }
            .navigationTitle("Kiwix")
            .toolbar { NewTabButton() }
        } detail: {
            NavigationStack(path: $path) {
                NavigationDestination(navigationItem: navigation.currentItem)
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationDestination(for: ZimFile.self) { zimFile in
                        ZimFileDetail(zimFile: zimFile)
                    }
                    .toolbarRole(.browser)
            }.onChange(of: navigation.currentItem) { _ in
                path = NavigationPath()
            }
        }
    }
}

struct RegularView_iOS15: View {
    @EnvironmentObject private var navigation: NavigationViewModel
    
    private let primaryItems: [NavigationItem] = [.bookmarks, .settings]
    private let libraryItems: [NavigationItem] = [.opened, .categories, .downloads, .new]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(primaryItems) { navigationItem in
                    makeNavigationLink(navigationItem)
                }
                Section("Tabs") {
                    TabsSectionContent()
                }
                Section("Library") {
                    ForEach(libraryItems) { navigationItem in
                        makeNavigationLink(navigationItem)
                    }
                }
            }
            .navigationTitle("Kiwix")
            .toolbar { NewTabButton() }
            NavigationDestination(navigationItem: navigation.currentItem)
        }
        .navigationViewStyle(.columns)
        .introspect(.navigationView(style: .columns), on: .iOS(.v15)) { controller in
            controller.preferredSplitBehavior = .tile
        }
    }
    
    @ViewBuilder
    private func makeNavigationLink(_ navigationItem: NavigationItem) -> NavigationLink<some View, some View> {
        NavigationLink(tag: navigationItem, selection: $navigation.currentItem) {
            NavigationDestination(navigationItem: navigationItem).navigationBarTitleDisplayMode(.inline)
        } label: {
            Label(navigationItem.name, systemImage: navigationItem.icon)
        }
    }
}

struct TabsSectionContent: View {
    @EnvironmentObject private var navigation: NavigationViewModel
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\Tab.created, order: .reverse)],
        animation: .easeInOut
    ) private var tabs: FetchedResults<Tab>
    
    private struct Item {
        let tab: Tab
        let navigationItem: NavigationItem
        
        init(tab: Tab) {
            self.tab = tab
            self.navigationItem = NavigationItem.tab(objectID: tab.objectID)
        }
    }
    
    var body: some View {
        ForEach(tabs.map({ Item(tab: $0) }), id: \.navigationItem) { item in
            Group {
                if #available(iOS 16.0, *) {
                    TabLabel(tab: item.tab)
                } else {
                    NavigationLink(tag: item.navigationItem, selection: $navigation.currentItem) {
                        NavigationDestination(navigationItem: item.navigationItem)
                    } label: {
                        TabLabel(tab: item.tab)
                    }
                }
            }
            .lineLimit(1)
            .swipeActions {
                Button(role: .destructive) {
                    Task { await navigation.deleteTab(tabID: item.tab.objectID) }
                } label: {
                    Label("Close Tab", systemImage: "xmark")
                }
            }
        }
    }
}

private struct NavigationDestination: View {
    let navigationItem: NavigationItem?
    
    var body: some View {
        Group {
            switch navigationItem {
            case .bookmarks:
                Bookmarks()
            case .settings:
                Settings()
            case .tab(let tabID):
                BrowserTab()
                    .id(tabID)
                    .environmentObject(WebViewCache.shared.getViewModel(tabID: tabID))
            case .opened:
                ZimFilesOpened()
            case .categories:
                ZimFilesCategories()
            case .downloads:
                ZimFilesDownloads()
            case .new:
                ZimFilesNew()
            default:
                EmptyView()
            }
        }.introspect(.viewController, on: .iOS(.v15)) { controller in
            if case .tab = navigationItem {
                controller.navigationItem.scrollEdgeAppearance = {
                    let apperance = UINavigationBarAppearance()
                    apperance.configureWithDefaultBackground()
                    return apperance
                }()
            } else {
                controller.navigationItem.scrollEdgeAppearance = {
                    let apperance = UINavigationBarAppearance()
                    apperance.configureWithTransparentBackground()
                    return apperance
                }()
            }
        }
    }
}
#endif
