//
//  SidebarDisplayModeSelector.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 12/25/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

struct SidebarDisplayModeSelector: View {
    @Binding var displayMode: SidebarDisplayMode
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 20) {
                Button { displayMode = .search } label: {
                    Image(systemName: "magnifyingglass").foregroundColor(displayMode == .search ? .blue : nil)
                }.help("Search among on device zim files")
                Button { displayMode = .bookmark } label: {
                    Image(systemName: "star").foregroundColor(displayMode == .bookmark ? .blue : nil)
                }.help("Show bookmarked articles")
                Button { displayMode = .tableOfContent } label: {
                    Image(systemName: "list.bullet").foregroundColor(displayMode == .tableOfContent ? .blue : nil)
                }.help("Show table of content of current article")
                Button { displayMode = .library } label: {
                    Image(systemName: "folder").foregroundColor(displayMode == .library ? .blue : nil)
                }.help("Show library of zim files")
            }.padding(.vertical, 6).buttonStyle(.borderless).frame(maxWidth: .infinity)
            Divider()
        }.background(.regularMaterial)
    }
}
