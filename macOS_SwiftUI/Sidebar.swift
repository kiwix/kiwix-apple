//
//  Sidebar.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 11/3/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

struct Sidebar: View {
    @SceneStorage("sidebarDisplayMode") var displayMode: SidebarDisplayMode = .search
    @Binding var url: URL?
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 20) {
                    Button { displayMode = .search } label: {
                        Image(systemName: "magnifyingglass").foregroundColor(displayMode == .search ? .blue : nil)
                    }.help("Search among on device zim files")
                    Button { displayMode = .bookmark } label: {
                        Image(systemName: "star").foregroundColor(displayMode == .bookmark ? .blue : nil)
                    }.help("Show sookmarked articles")
                    Button { displayMode = .tableOfContent } label: {
                        Image(systemName: "list.bullet").foregroundColor(displayMode == .tableOfContent ? .blue : nil)
                    }.help("Show table of content of current article")
                    Button { displayMode = .library } label: {
                        Image(systemName: "folder").foregroundColor(displayMode == .library ? .blue : nil)
                    }.help("Show library of zim files")
                }.padding(.vertical, 6).buttonStyle(.borderless).frame(maxWidth: .infinity)
                Divider()
            }.background(.regularMaterial)
            switch displayMode {
            case .search:
                Search(url: $url).listStyle(.sidebar)
            case .bookmark:
                List {
                    Text("bookmarks")
                }
            case .tableOfContent:
                List {
                    Text("table of contents")
                }
            case .library:
                Library()
            }
        }.focusedSceneValue(\.sidebarDisplayMode, $displayMode)
    }
}

enum SidebarDisplayMode: String {
    case search, bookmark, tableOfContent, library
}
