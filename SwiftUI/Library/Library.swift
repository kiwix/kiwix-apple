//
//  Library.swift
//  Kiwix
//
//  Created by Chris Li on 4/23/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

#if os(iOS)
/// Tabbed library view on iOS & iPadOS
struct Library: View {
    @Binding var url: URL?
    @EnvironmentObject private var libraryViewModel: LibraryViewModel
    @SceneStorage("LibraryNavigationItem") private var navigationItem: NavigationItem = .opened
    
    private let navigationItems: [NavigationItem] = [.opened, .categories, .downloads, .new]
    private let defaultNavigationItem: NavigationItem?
    
    init(url: Binding<URL?>, navigationItem: NavigationItem? = nil) {
        self._url = url
        self.defaultNavigationItem = navigationItem
    }
    
    var body: some View {
        TabView(selection: $navigationItem) {
            ForEach(navigationItems) { navigationItem in
                SheetView {
                    switch navigationItem {
                    case .opened:
                        ZimFilesOpened(url: $url)
                    case .categories:
                        List(Category.allCases) { category in
                            NavigationLink {
                                ZimFilesCategory(category: .constant(category), url: $url)
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
                        ZimFilesDownloads(url: $url)
                    case .new:
                        ZimFilesNew(url: $url)
                    default:
                        EmptyView()
                    }
                }
                .tag(navigationItem)
                .tabItem { Label(navigationItem.name, systemImage: navigationItem.icon) }
            }
        }
        .onAppear {
            if let defaultNavigationItem = defaultNavigationItem {
                navigationItem = defaultNavigationItem
            }
            libraryViewModel.startRefresh(isUserInitiated: false)
        }
    }
}
#endif
