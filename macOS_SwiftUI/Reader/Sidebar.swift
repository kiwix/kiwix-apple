//
//  Sidebar.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 11/3/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

struct Sidebar: View {
    @SceneStorage("sidebarDisplayMode") private var displayMode: DisplayMode = .search
    @Binding var url: URL?
    
    var body: some View {
        VStack(spacing: 0) {
            displayModeSelector
            Divider()
            switch displayMode {
            case .search:
                Search(url: $url)
            case .bookmark:
                BookmarksList(url: $url)
            case .tableOfContent:
                List {
                    Text("table of contents")
                }
            case .library:
                LibraryList(url: $url)
            }
        }.focusedSceneValue(\.sidebarDisplayMode, $displayMode)
    }
    
    var displayModeSelector: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 20) {
                ForEach(DisplayMode.allCases) { displayMode in
                    Button {
                        self.displayMode = displayMode
                    } label: {
                        Image(systemName: displayMode.imageName)
                            .foregroundColor(self.displayMode == displayMode ? .blue : nil)
                    }.help(displayMode.help)
                }
            }.padding(.vertical, 6).buttonStyle(.borderless).frame(maxWidth: .infinity)
        }.background(.regularMaterial)
    }
    
    enum DisplayMode: String, CaseIterable, Identifiable {
        var id: String { rawValue }
        case search, bookmark, tableOfContent, library
        
        var imageName: String {
            switch self {
            case .search:
                return "magnifyingglass"
            case .bookmark:
                return "star"
            case .tableOfContent:
                return "list.bullet"
            case .library:
                return "folder"
            }
        }
        
        var help: String {
            switch self {
            case .search:
                return "Search for articles"
            case .bookmark:
                return "Show bookmarked articles"
            case .tableOfContent:
                return "Show table of content of current article"
            case .library:
                return "Show library of zim files"
            }
        }
    }
}

struct Sidebar_Previews: PreviewProvider {
    static var previews: some View {
        Sidebar(url: .constant(nil))
            .frame(width: 250, height: 550)
            .listStyle(.sidebar)
    }
}
