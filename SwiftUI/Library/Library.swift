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
    @SceneStorage("LibraryTabItem") private var tabItem: LibraryTabItem = .opened
    
    private let defaultTabItem: LibraryTabItem?
    
    init(url: Binding<URL?>, tabItem: LibraryTabItem? = nil) {
        self._url = url
        self.defaultTabItem = tabItem
    }
    
    var body: some View {
        TabView(selection: $tabItem) {
            ForEach(LibraryTabItem.allCases) { tabItem in
                SheetContent {
                    switch tabItem {
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
                    }
                }
                .tag(tabItem)
                .tabItem { Label(tabItem.name, systemImage: tabItem.icon) }
            }
        }
        .onAppear {
            if let defaultTabItem = defaultTabItem {
                tabItem = defaultTabItem
            }
            libraryViewModel.startRefresh(isUserInitiated: false)
        }
    }
}
#endif
