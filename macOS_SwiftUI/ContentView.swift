//
//  ContentView.swift
//  Kiwix
//
//  Created by Chris Li on 10/19/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @SceneStorage("sidebarDisplayMode") private var sidebarDisplayMode: Sidebar.DisplayMode = .search
    
    var body: some View {
        NavigationView {
            Sidebar(displayMode: $sidebarDisplayMode)
                .frame(minWidth: 250)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button { toggleSidebar() } label: { Image(systemName: "sidebar.leading") }
                    }
                }
            WebView()
                .frame(idealWidth: 800, minHeight: 300, idealHeight: 350)
                .toolbar {
                    ToolbarItemGroup(placement: .navigation) {
                        Button { } label: { Image(systemName: "chevron.backward") }
                        Button { } label: { Image(systemName: "chevron.forward") }
                    }
                    ToolbarItemGroup {
                        Button { } label: { Image(systemName: "house") }
                        Button { } label: { Image(systemName: "die.face.5") }
                    }
                }
        }
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}
