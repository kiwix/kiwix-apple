//
//  KiwixApp.swift
//  Kiwix
//
//  Created by Chris Li on 10/19/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI
import RealmSwift

@main
struct Kiwix: SwiftUI.App {
    init() {
        Realm.Configuration.defaultConfiguration = Realm.defaultConfig
        LibraryOperationQueue.shared.addOperation(LibraryScanOperation())
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }.commands {
            SidebarCommands()
            CommandGroup(after: CommandGroupPlacement.newItem) {
                Button("New Tab") { newTab() }.keyboardShortcut("t")
                Divider()
                Button("Open...") { open() }.keyboardShortcut("o")
            }
        }
    }
    
    private func newTab() {
        guard let currentWindow = NSApp.keyWindow, let windowController = currentWindow.windowController else { return }
        windowController.newWindowForTab(nil)
        guard let newWindow = NSApp.keyWindow, currentWindow != newWindow else { return }
        currentWindow.addTabbedWindow(newWindow, ordered: .above)
    }
    
    private func open() {
        guard let window = NSApp.keyWindow else { return }
        let panel = NSOpenPanel()
        panel.showsHiddenFiles = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = ["zim"]
        panel.beginSheetModal(for: window) { response in
            guard response == .OK, let url = panel.urls.first else { return }
            LibraryOperationQueue.shared.addOperation(LibraryScanOperation(url: url))
        }
    }
}
