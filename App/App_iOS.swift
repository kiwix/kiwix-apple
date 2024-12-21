import SwiftUI
import UserNotifications
import ActivityKit

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

        /// Handling Live Activities for download progress
        func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
            // Handle device token registration for Live Activities
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

struct DownloadActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var progress: Double
        var speed: Double
    }

    var fileID: UUID
    var fileName: String
}
#endif
