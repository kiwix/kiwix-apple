//
//  macOS_SwiftUIApp.swift
//  macOS_SwiftUI
//
//  Created by Chris Li on 10/10/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

@main
struct Kiwix: App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                VSplitView {
                    VStack {
                        SearchField().padding(.horizontal).padding(.top, 10)
                        List {
                            Text("result 1")
                            Text("result 2")
                        }.listStyle(SidebarListStyle())
                    }
                    List {
                        Text("zim file 1")
                        Text("zim file 2")
                    }.listStyle(SidebarListStyle())
                }
                .frame(minWidth: 250)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button { toggleSidebar() } label: { Image(systemName: "sidebar.leading") }
                    }
                }
                Text("Table of Content")
                Text("Content")
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
            .navigationTitle("Article Name")
            .navigationSubtitle("example.zim")
        }
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}

struct SearchField: NSViewRepresentable {
    func makeNSView(context: Context) -> some NSView {
        NSSearchField()
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
        
    }
}
