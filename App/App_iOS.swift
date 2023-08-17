//
//  App_iOS.swift
//  Kiwix
//
//  Created by Chris Li on 7/27/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import SwiftUI
import UserNotifications

#if os(iOS)
@main
struct Kiwix: App {
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
            RootView().environment(\.managedObjectContext, Database.viewContext)
        }
        .commands {
//            CommandGroup(replacing: .importExport) {
//                FileImportButton { Text("Open...") }
//            }
            CommandGroup(replacing: .textFormatting) {
//                NavigationCommandButtons()
                PageZoomCommands()
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

struct RootView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var library = LibraryViewModel()
    @StateObject private var navigation = NavigationViewModel()
    
    private let primaryItems: [NavigationItem] = [.bookmarks, .settings]
    private let libraryItems: [NavigationItem] = [.opened, .categories, .downloads, .new]
    private let openURL = NotificationCenter.default.publisher(for: .openURL)
    
    var body: some View {
        Group {
            if #available(iOS 16.0, *) {
                if horizontalSizeClass == .regular {
                    RegularView()
                } else {
                    ContainerView {
                        CompactView()
                    }
                    .ignoresSafeArea()
                    .onAppear() {
                        navigation.navigateToMostRecentTab()
                    }
                }
            } else {
                ContainerView {
                    LegacyView()
                }.ignoresSafeArea()
            }
        }
        .focusedSceneValue(\.navigationItem, $navigation.currentItem)
        .environmentObject(library)
        .environmentObject(navigation)
        .modifier(AlertHandler())
        .modifier(ExternalLinkHandler())
        .onChange(of: scenePhase) { newScenePhase in
            guard newScenePhase == .inactive else { return }
            WebViewCache.shared.persistStates()
        }
        .onOpenURL { url in
            NotificationCenter.openURL(url)
        }
        .onReceive(openURL) { notification in
            guard let url = notification.userInfo?["url"] as? URL else { return }
            if #available(iOS 16.0, *) {
                if case let .tab(tabID) = navigation.currentItem {
                    WebViewCache.shared.getWebView(tabID: tabID).load(URLRequest(url: url))
                } else {
                    let tabID = navigation.createTab()
                    WebViewCache.shared.getWebView(tabID: tabID).load(URLRequest(url: url))
                }
            } else {
                WebViewCache.shared.webView.load(URLRequest(url: url))
            }
        }
    }
}
#endif
