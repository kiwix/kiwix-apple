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
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var library = LibraryViewModel()
    @StateObject private var navigation = NavigationViewModel()
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
            RootView()
                .ignoresSafeArea()
                .environment(\.managedObjectContext, Database.viewContext)
                .environmentObject(library)
                .environmentObject(navigation)
                .modifier(AlertHandler())
                .modifier(OpenFileHandler())
                .onChange(of: scenePhase) { newValue in
                    guard newValue == .inactive else { return }
                    try? Database.viewContext.save()
                }
                .onOpenURL { url in
                    if url.isFileURL {
                        NotificationCenter.openFiles([url], context: .file)
                    } else if url.scheme == "kiwix" {
                        NotificationCenter.openURL(url)
                    }
                }
        }
        .commands {
            CommandGroup(replacing: .undoRedo) {
                NavigationCommands()
            }
            CommandGroup(replacing: .textFormatting) {
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
                NotificationCenter.openURL(mainPageURL, inNewTab: true)
            }
            completionHandler()
        }
    }
}

private struct RootView: UIViewControllerRepresentable {
    @EnvironmentObject private var navigation: NavigationViewModel
    
    func makeUIViewController(context: Context) -> SplitViewController {
        SplitViewController(navigationViewModel: navigation)
    }
    
    func updateUIViewController(_ controller: SplitViewController, context: Context) {
    }
}
#endif
