//
//  KiwixApp.swift
//  Kiwix
//
//  Created by Chris Li on 10/19/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

@main
struct Kiwix: App {
    init() {
        self.reopen()
    }
    
    var body: some Scene {
        WindowGroup {
            Reader().environment(\.managedObjectContext, Database.shared.container.viewContext)
        }.commands {
            ImportCommands()
            SidebarDisplayModeCommands()
            CommandGroup(replacing: .newItem) {
                Button("New Tab") { newTab() }.keyboardShortcut("t")
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
        }.handlesExternalEvents(matching: [WindowGroupTitle.reading.rawValue])
        WindowGroup(WindowGroupTitle.library.rawValue) {
            Library().environment(\.managedObjectContext, Database.shared.container.viewContext)
        }.commands {
            SidebarCommands()
            ImportCommands()
        }.handlesExternalEvents(matching: [WindowGroupTitle.library.rawValue])
        Settings {
            TabView {
                Message(text: "Library").tabItem { Label("Library", systemImage: "folder.badge.gearshape") }
                Message(text: "Language").tabItem { Label("Language", systemImage: "globe") }
                About()
            }.frame(width: 480)
        }
    }
    
    private func newTab() {
        guard let currentWindow = NSApp.keyWindow, let windowController = currentWindow.windowController else { return }
        windowController.newWindowForTab(nil)
        guard let newWindow = NSApp.keyWindow, currentWindow != newWindow else { return }
        currentWindow.addTabbedWindow(newWindow, ordered: .above)
    }
    
    private func reopen() {
        let context = Database.shared.container.viewContext
        let request = ZimFile.fetchRequest(predicate: NSPredicate(format: "fileURLBookmark != nil"))
        guard let zimFiles = try? context.fetch(request) else { return }
        zimFiles.forEach { zimFile in
            guard let data = zimFile.fileURLBookmark else { return }
            if let data = ZimFileService.shared.open(bookmark: data) {
                zimFile.fileURLBookmark = data
            }
        }
        if context.hasChanges {
            try? context.save()
        }
    }
    
    private enum WindowGroupTitle: String, CaseIterable, Identifiable {
        var id: String { rawValue }
        
        case reading = "Reading"
        case library = "Library"
    }
}
