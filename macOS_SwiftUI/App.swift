//
//  KiwixApp.swift
//  Kiwix
//
//  Created by Chris Li on 10/19/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

@main
struct Kiwix: SwiftUI.App {
    init() {
        ZimFileDataProvider.reopen()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, Database.shared.container.viewContext)
        }.commands {
            SidebarCommands()
            CommandGroup(replacing: .newItem) {
                Button("New Tab") { newTab() }.keyboardShortcut("t")
                Divider()
                FileImportButton()
            }
            CommandGroup(before: .sidebar) {
                SidebarDisplayModeCommandButtons()
                Divider()
            }
            CommandMenu("Navigation") { NavigationCommandButtons() }
        }
    }
    
    private func newTab() {
        guard let currentWindow = NSApp.keyWindow, let windowController = currentWindow.windowController else { return }
        windowController.newWindowForTab(nil)
        guard let newWindow = NSApp.keyWindow, currentWindow != newWindow else { return }
        currentWindow.addTabbedWindow(newWindow, ordered: .above)
    }
}
