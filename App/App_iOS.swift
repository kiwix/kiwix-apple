// This file is part of Kiwix for iOS & macOS.
//
// Kiwix is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// any later version.
//
// Kiwix is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Kiwix; If not, see https://www.gnu.org/licenses/.

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
//    private let activityService: ActivityService?

    init() {
        fileMonitor = DirectoryMonitor(url: URL.documentDirectory) { LibraryOperations.scanDirectory($0) }
        // MARK: - live activities
//        switch AppType.current {
//        case .kiwix:
//            activityService = ActivityService()
//        case .custom:
//            activityService = nil
//        }
        UNUserNotificationCenter.current().delegate = appDelegate
        // MARK: - migrations
        if !ProcessInfo.processInfo.arguments.contains("testing") {
            _ = MigrationService().migrateAll()
        }
        
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .ignoresSafeArea()
                .environment(\.managedObjectContext, Database.shared.viewContext)
                .environmentObject(library)
                .environmentObject(navigation)
                .modifier(AlertHandler())
                .modifier(OpenFileHandler())
                .modifier(FileExportHandler())
                .modifier(SaveContentHandler())
                .onChange(of: scenePhase) { newValue in
                    switch newValue {
                    case .inactive:
                        try? Database.shared.viewContext.save()
                    case .active:
                        if FeatureFlags.hasLibrary {
                            library.start(isUserInitiated: false)
                        }
                    case .background:
                        break
                    @unknown default:
                        break
                    }
                }
                .onOpenURL { url in
                    if url.isFileURL {
                        NotificationCenter.openFiles([url], context: .file)
                    } else if url.isZIMURL {
                        NotificationCenter.openURL(url)
                    }
                }
                .task {
                    switch AppType.current {
                    case .kiwix:
                        fileMonitor.start()
                        await LibraryOperations.reopen()
                        navigation.navigateToMostRecentTab()
                        LibraryOperations.scanDirectory(URL.documentDirectory)
                        LibraryOperations.applyFileBackupSetting()
                        DownloadService.shared.restartHeartbeatIfNeeded()
//                        activityService?.start()
                    case let .custom(zimFileURL):
                        await LibraryOperations.open(url: zimFileURL)
                        ZimMigration.forCustomApps()
                        navigation.navigateToMostRecentTab()
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
            Task { @MainActor in
                if let zimFileID = UUID(uuidString: response.notification.request.identifier),
                   let mainPageURL = await ZimFileService.shared.getMainPageURL(zimFileID: zimFileID) {
                    NotificationCenter.openURL(mainPageURL, inNewTab: true)
                }
                completionHandler()
            }
        }

        /// Purge some cached browser view models when receiving memory warning
        func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
            BrowserViewModel.purgeCache()
        }
    }
}

private struct RootView: UIViewControllerRepresentable {
    @EnvironmentObject private var navigation: NavigationViewModel
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.openedPredicate,
        animation: .easeInOut
    ) private var zimFiles: FetchedResults<ZimFile>

    func makeUIViewController(context: Context) -> SplitViewController {
        SplitViewController(
            navigationViewModel: navigation,
            hasZimFiles: !zimFiles.isEmpty
        )
    }

    func updateUIViewController(_ controller: SplitViewController, context: Context) {
    }
}
#endif
