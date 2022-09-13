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
    private let fileMonitor: DirectoryMonitor
    
    init() {
        fileMonitor = DirectoryMonitor(url: URL.documentDirectory) { LibraryOperations.scanDirectory($0) }
        LibraryViewModel.reopen()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, Database.shared.container.viewContext)
        }.commands {
            CommandGroup(replacing: .importExport) {
                FileImportButton()
            }
            #if os(macOS)
            CommandGroup(replacing: .newItem) {
                Button("New Tab") {
                    guard let currentWindow = NSApp.keyWindow, let controller = currentWindow.windowController else { return }
                    controller.newWindowForTab(nil)
                    guard let newWindow = NSApp.keyWindow, currentWindow != newWindow else { return }
                    currentWindow.addTabbedWindow(newWindow, ordered: .above)
                }.keyboardShortcut("t")
                Divider()
            }
            CommandGroup(after: .toolbar) {
                NavigationButtons()
                Divider()
                PageZoomButtons()
                Divider()
                SidebarNavigationItemButtons()
                Divider()
            }
            #elseif os(iOS)
            CommandGroup(after: .toolbar) {
                NavigationButtons()
                Divider()
            }
            #endif
        }
        #if os(macOS)
        Settings {
            TabView {
                LibrarySettings_macOS()
                About()
            }.frame(width: 550, height: 400)
        }
        #endif
    }
}
