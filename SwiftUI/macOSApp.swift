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
            CommandGroup(replacing: .newItem) {
                Button("New Reader Window") { NSWorkspace.shared.open(Window.reader.url) }.keyboardShortcut("n")
                Button("New Tab") { newTab() }.keyboardShortcut("t")
                Button("Open Library") { NSWorkspace.shared.open(Window.library.url) }.keyboardShortcut("l")
                Divider()
            }
            CommandGroup(after: .toolbar) {
                SidebarDisplayModeCommandButtons()
                Divider()
                NavigationCommandButtons()
                Divider()
                PageZoomCommandButtons()
            }
        }.handlesExternalEvents(matching: [Window.reader.url.absoluteString, "kiwix://", "file:///"])
        WindowGroup(Window.library.name) {
            Library()
                .environment(\.managedObjectContext, Database.shared.container.viewContext)
                .frame(minWidth: 950, idealWidth: 1250, minHeight: 550, idealHeight: 750)
        }.commands {
            SidebarCommands()
            ImportCommands()
        }.handlesExternalEvents(matching: [Window.library.url.absoluteString])
        Settings {
            TabView {
                LibrarySettings()
                About()
            }.frame(width: 550, height: 400)
        }
    }
    
    private func newTab() {
        guard let currentWindow = NSApp.keyWindow, let controller = currentWindow.windowController else { return }
        controller.newWindowForTab(nil)
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
    
    private enum Window: String, CaseIterable, Identifiable {
        var id: String { rawValue }
        
        case reader, library
        
        var name: String {
            switch self {
            case .reader:
                return "Reader"
            case .library:
                return "Library"
            }
        }
        
        var url: URL {
            switch self {
            case .reader:
                return URL(string: "kiwix-ui://reader")!
            case .library:
                return URL(string: "kiwix-ui://library")!
            }
        }
    }
}
