//
//  App.swift
//  Kiwix
//
//  Created by Chris Li on 7/31/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers
import UserNotifications

#if os(macOS)
@main
struct Kiwix: App {
    @StateObject private var libraryRefreshViewModel = LibraryRefreshViewModel()
    
    static let zimFileType = UTType(exportedAs: "org.openzim.zim")
    
    private let notificationCenterDelegate = NotificationCenterDelegate()
    
    init() {
        UNUserNotificationCenter.current().delegate = notificationCenterDelegate
        LibraryOperations.reopen()
        LibraryOperations.scanDirectory(URL.documentDirectory)
        LibraryOperations.applyFileBackupSetting()
        DownloadService.shared.restartHeartbeatIfNeeded()
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
                NavigationCommandButtons()
                Divider()
                PageZoomButtons()
                Divider()
                SidebarNavigationItemButtons()
                Divider()
            }
        }
        Settings { SettingsContent().environmentObject(libraryRefreshViewModel) }
    }
    
    private class NotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate {
        /// Handling file download complete notification
        func userNotificationCenter(_ center: UNUserNotificationCenter,
                                    didReceive response: UNNotificationResponse,
                                    withCompletionHandler completionHandler: @escaping () -> Void) {
            if let zimFileID = UUID(uuidString: response.notification.request.identifier),
               let mainPageURL = ZimFileService.shared.getMainPageURL(zimFileID: zimFileID) {
                NSWorkspace.shared.open(mainPageURL)
            }
            completionHandler()
        }
    }
}
#elseif os(iOS)
struct Kiwix: App {
    @StateObject private var libraryRefreshViewModel = LibraryRefreshViewModel()
    
    static let zimFileType = UTType(exportedAs: "org.openzim.zim")
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    private let fileMonitor: DirectoryMonitor
    
    init() {
        fileMonitor = DirectoryMonitor(url: URL.documentDirectory) { LibraryOperations.scanDirectory($0) }
        UNUserNotificationCenter.current().delegate = appDelegate
        LibraryOperations.reopen()
        LibraryOperations.scanDirectory(URL.documentDirectory)
        LibraryOperations.applyFileBackupSetting()
        LibraryOperations.registerBackgroundTask()
        LibraryOperations.applyLibraryAutoRefreshSetting()
        DownloadService.shared.restartHeartbeatIfNeeded()
    }
    
    var body: some Scene {
        WindowGroup {
            EmptyView()
                .environment(\.managedObjectContext, Database.shared.container.viewContext)
                .environmentObject(libraryRefreshViewModel)
        }.commands {
            CommandGroup(replacing: .importExport) {
                FileImportButton { Text("Open...") }
            }
            CommandGroup(after: .toolbar) {
                NavigationCommandButtons()
                Divider()
            }
        }
    }
    
    private class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
        /// Storing background download completion handler sent to application delegate
        func application(_ application: UIApplication,
                         handleEventsForBackgroundURLSession identifier: String,
                         completionHandler: @escaping () -> Void) {
            DownloadService.shared.backgroundCompletionHandler = completionHandler
        }
        
        /// Handling file download complete notification
        func userNotificationCenter(_ center: UNUserNotificationCenter,
                                    didReceive response: UNNotificationResponse,
                                    withCompletionHandler completionHandler: @escaping () -> Void) {
            if let zimFileID = UUID(uuidString: response.notification.request.identifier),
               let mainPageURL = ZimFileService.shared.getMainPageURL(zimFileID: zimFileID) {
                UIApplication.shared.open(mainPageURL)
            }
            completionHandler()
        }
    }
}
#endif
