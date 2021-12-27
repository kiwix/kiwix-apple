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
            SidebarDisplayModeSelector(displayMode: $displayMode)
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
                List {
                    Text("library")
                }
            }
        }.focusedSceneValue(\.sidebarDisplayMode, $displayMode)
    }
}
