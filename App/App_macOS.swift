//
//  App_macOS.swift
//  Kiwix
//
//  Created by Chris Li on 8/13/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import SwiftUI
import UserNotifications

#if os(macOS)
@main
struct Kiwix: App {
    @StateObject private var libraryRefreshViewModel = LibraryViewModel()
    
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
                PageZoomCommands()
                Divider()
                SidebarNavigationItemButtons()
                Divider()
            }
        }
        Settings {
            TabView {
                ReadingSettings()
                LibrarySettings()
                About()
            }
            .frame(width: 550, height: 400)
            .environmentObject(libraryRefreshViewModel)
        }
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

struct RootView: View {
    @StateObject private var navigation = NavigationViewModel()
    
    private let primaryItems: [NavigationItem] = [.reading, .bookmarks]
    private let libraryItems: [NavigationItem] = [.opened, .categories, .downloads, .new]
    private let openURL = NotificationCenter.default.publisher(for: Notification.Name.openURL)
    
    var body: some View {
        NavigationView {
            List(selection: $navigation.currentItem) {
                ForEach(primaryItems, id: \.self) { navigationItem in
                    Label(navigationItem.name, systemImage: navigationItem.icon)
                }
                Section("Library") {
                    ForEach(libraryItems, id: \.self) { navigationItem in
                        Label(navigationItem.name, systemImage: navigationItem.icon)
                    }
                }
            }.frame(minWidth: 150).toolbar { SidebarButton() }
            switch navigation.currentItem {
            case .reading:
                ReadingView()
            case .bookmarks:
                Bookmarks()
            case .opened:
                ZimFilesOpened().modifier(LibraryZimFileDetailSidePanel())
            case .categories:
                ZimFilesCategories().modifier(LibraryZimFileDetailSidePanel())
            case .downloads:
                ZimFilesDownloads().modifier(LibraryZimFileDetailSidePanel())
            case .new:
                ZimFilesNew().modifier(LibraryZimFileDetailSidePanel())
            default:
                EmptyView()
            }
        }
        .frame(minWidth: 650, minHeight: 500)
        .focusedSceneValue(\.navigationItem, $navigation.currentItem)
        .environmentObject(navigation)
        .modifier(AlertHandler())
        .modifier(ExternalLinkHandler())
        .onOpenURL { url in
            if url.isFileURL {
                guard let metadata = ZimFileService.getMetaData(url: url) else { return }
                LibraryOperations.open(url: url)
//                self.url = ZimFileService.shared.getMainPageURL(zimFileID: metadata.fileID)
            } else if url.scheme == "kiwix" {
                NotificationCenter.default.post(name: Notification.Name.openURL, object: nil, userInfo: ["url": url])
            }
        }
        .onReceive(openURL) { notification in
            guard let url = notification.userInfo?["url"] as? URL else { return }
            WebViewCache.shared.webView.load(URLRequest(url: url))
            navigation.currentItem = .reading
        }
    }
}
#endif
