//
//  App.swift
//  Kiwix
//
//  Created by Chris Li on 7/31/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

@main
struct Kiwix: App {
    init() {
        LibraryViewModel.reopen()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }.commands {
            ImportCommands()
            CommandGroup(after: .toolbar) {
                #if os(macOS)
                NavigationButtons()
                Divider()
                PageZoomButtons()
                Divider()
                SidebarNavigationItemButtons()
                Divider()
                #endif
            }
        }
    }
}

struct ImportCommands: Commands {
    @State private var isPresented: Bool = false
    
    var body: some Commands {
        CommandGroup(replacing: .importExport) {
            Section {
                Button("Open...") { isPresented = true}
                    .modifier(FileImporter(isPresented: $isPresented))
                    .keyboardShortcut("o")
            }
        }
    }
}
