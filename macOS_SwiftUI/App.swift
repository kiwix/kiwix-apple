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
            ContentView().environment(\.managedObjectContext, Database.shared.container.viewContext)
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
            CommandGroup(after: .windowSize) {
                Divider()
                ForEach(WindowGroupTitle.allCases) { windowGroup in
                    Button(windowGroup.rawValue) {
                        guard let url = URL(string: "kiwix://\(windowGroup.rawValue)") else { return }
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }.handlesExternalEvents(matching: [WindowGroupTitle.view.rawValue])
        WindowGroup(WindowGroupTitle.library.rawValue) {
            Library().environment(\.managedObjectContext, Database.shared.container.viewContext)
        }.handlesExternalEvents(matching: [WindowGroupTitle.library.rawValue])
    }
    
    private func newTab() {
        guard let currentWindow = NSApp.keyWindow, let windowController = currentWindow.windowController else { return }
        windowController.newWindowForTab(nil)
        guard let newWindow = NSApp.keyWindow, currentWindow != newWindow else { return }
        currentWindow.addTabbedWindow(newWindow, ordered: .above)
    }
    
    private enum WindowGroupTitle: String, Identifiable, CaseIterable {
        var id: String { self.rawValue }
        
        case view = "View"
        case library = "Library"
    }
}
