//
//  Sidebar.swift
//  macOS_SwiftUI
//
//  Created by Chris Li on 11/3/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

struct Sidebar: View {
    @State private var displayMode: DisplayMode = .search
    
    var body: some View {
        VStack {
            Divider()
            HStack(spacing: 20) {
                Button { displayMode = .search } label: {
                    Image(systemName: "magnifyingglass").foregroundColor(displayMode == .search ? .blue : nil)
                }
                Button { displayMode = .bookmark } label: {
                    Image(systemName: "star").foregroundColor(displayMode == .bookmark ? .blue : nil)
                }
                Button { displayMode = .tableOfContent } label: {
                    Image(systemName: "list.bullet").foregroundColor(displayMode == .tableOfContent ? .blue : nil)
                }
                Button { displayMode = .library } label: {
                    Image(systemName: "folder").foregroundColor(displayMode == .library ? .blue : nil)
                }
            }.buttonStyle(.borderless).frame(maxWidth: .infinity)
            Divider()
            switch displayMode {
            case .search:
                SearchField().padding(.horizontal, 6)
                Button("Scope") { }
                Divider()
                List {
                    Text("result 1")
                    Text("result 2")
                    Text("result 3")
                }
            case .bookmark:
                List {
                    Text("bookmarks")
                }
            case .tableOfContent:
                List {
                    Text("table of contents")
                }
            case .library:
                List {
                    Text("library")
                }
            }
        }
        .frame(minWidth: 250)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { toggleSidebar() } label: { Image(systemName: "sidebar.leading") }
            }
        }
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
    
    enum DisplayMode {
        case search, bookmark, tableOfContent, library
    }
}

private struct SearchField: NSViewRepresentable {
    func makeNSView(context: Context) -> some NSView {
        NSSearchField()
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
        
    }
}
