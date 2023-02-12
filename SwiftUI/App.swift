//
//  App.swift
//  Kiwix
//
//  Created by Chris Li on 7/31/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

@main
struct Kiwix: App {
    @StateObject private var libraryRefreshViewModel = LibraryRefreshViewModel()
    
    static let zimFileType = UTType(exportedAs: "org.openzim.zim")
    
    private let fileMonitor: DirectoryMonitor
    
    init() {
        fileMonitor = DirectoryMonitor(url: URL.documentDirectory) { LibraryOperations.scanDirectory($0) }
        LibraryOperations.reopen()
        LibraryOperations.scanDirectory(URL.documentDirectory)
        LibraryOperations.applyFileBackupSetting()
        #if os(iOS)
        LibraryOperations.registerBackgroundTask()
        LibraryOperations.applyLibraryAutoRefreshSetting()
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, Database.shared.container.viewContext)
                .environmentObject(libraryRefreshViewModel)
        }.commands {
            CommandGroup(replacing: .importExport) {
                FileImportButton { Text("Open...") }
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
        Settings { SettingsContent().environmentObject(libraryRefreshViewModel) }
        #endif
    }
}
