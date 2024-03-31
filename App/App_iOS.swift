/*
 * This file is part of Kiwix for iOS & macOS.
 *
 * Kiwix is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * any later version.
 *
 * Kiwix is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Kiwix; If not, see https://www.gnu.org/licenses/.
*/

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
        LibraryOperations.registerBackgroundTask()
        UNUserNotificationCenter.current().delegate = appDelegate
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
                .task {
                    switch AppType.current {
                    case .kiwix:
                        fileMonitor.start()
                        LibraryOperations.reopen {
                            navigation.navigateToMostRecentTab()
                        }
                        LibraryOperations.scanDirectory(URL.documentDirectory)
                        LibraryOperations.applyFileBackupSetting()
                        LibraryOperations.applyLibraryAutoRefreshSetting()
                        DownloadService.shared.restartHeartbeatIfNeeded()
                    case let .custom(zimFileURL):
                        LibraryOperations.open(url: zimFileURL) {
                            Task {
                                await ZimMigration.forCustomApps()
                                navigation.navigateToMostRecentTab()
                            }
                        }
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
        
        /// Purge some cached browser view models when receiving memory warning
        func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
            BrowserViewModel.purgeCache()
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
