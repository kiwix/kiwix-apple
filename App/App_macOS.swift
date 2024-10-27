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
import Combine
import Defaults
import CoreKiwix

#if os(macOS)
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

@main
struct Kiwix: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var libraryRefreshViewModel = LibraryViewModel()
    private let notificationCenterDelegate = NotificationCenterDelegate()

    init() {
        UNUserNotificationCenter.current().delegate = notificationCenterDelegate
        if FeatureFlags.hasLibrary {
            LibraryViewModel().start(isUserInitiated: false)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, Database.shared.viewContext)
                .environmentObject(libraryRefreshViewModel)
        }.commands {
            SidebarCommands()
            CommandGroup(replacing: .importExport) {
                OpenFileButton(context: .command) { Text("app_macos_commands.open_file".localized) }
            }
            CommandGroup(replacing: .newItem) {
                Button("app_macos_commands.new".localized) {
                    guard let currentWindow = NSApp.keyWindow,
                          let controller = currentWindow.windowController else { return }
                    controller.newWindowForTab(nil)
                    guard let newWindow = NSApp.keyWindow, currentWindow != newWindow else { return }
                    currentWindow.addTabbedWindow(newWindow, ordered: .above)
                }.keyboardShortcut("t")
                Divider()
            }
            CommandGroup(after: .toolbar) {
                NavigationCommands()
                Divider()
                PageZoomCommands()
                Divider()
                SidebarNavigationCommands()
                Divider()
            }
        }
        Settings {
            TabView {
                ReadingSettings()
                if FeatureFlags.hasLibrary {
                    LibrarySettings()
                        .environmentObject(libraryRefreshViewModel)
                }
                About()
            }
            .frame(width: 550, height: 400)
        }
    }

    private class NotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate {
        /// Handling file download complete notification
        func userNotificationCenter(_ center: UNUserNotificationCenter,
                                    didReceive response: UNNotificationResponse,
                                    withCompletionHandler completionHandler: @escaping () -> Void) {
            Task {
                if let zimFileID = UUID(uuidString: response.notification.request.identifier),
                   let mainPageURL = await ZimFileService.shared.getMainPageURL(zimFileID: zimFileID) {
                    NSWorkspace.shared.open(mainPageURL)
                }
                await MainActor.run { completionHandler() }
            }
        }
    }
}

struct RootView: View {
    @Environment(\.controlActiveState) var controlActiveState
    @StateObject private var browser = BrowserViewModel()
    @StateObject private var navigation = NavigationViewModel()
    @StateObject private var windowTracker = WindowTracker()

    private let primaryItems: [NavigationItem] = [.reading, .bookmarks]
    private let libraryItems: [NavigationItem] = [.opened, .categories, .downloads, .new]
    private let openURL = NotificationCenter.default.publisher(for: .openURL)
    private let appTerminates = NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)
    private let tabCloses = NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)
    private let browserClearModel = BrowserClearViewModel()
    private let closeZimPublisher = NotificationCenter.default.publisher(for: .closeZIM)

    var body: some View {
        NavigationSplitView {
            List(selection: $navigation.currentItem) {
                ForEach(primaryItems, id: \.self) { navigationItem in
                    Label(navigationItem.name, systemImage: navigationItem.icon)
                }
                if FeatureFlags.hasLibrary {
                    Section("app_macos_navigation.button.library".localized) {
                        ForEach(libraryItems, id: \.self) { navigationItem in
                            Label(navigationItem.name, systemImage: navigationItem.icon)
                        }
                    }
                }
            }
            .frame(minWidth: 150)
        } detail: {
            switch navigation.currentItem {
            case .loading:
                LoadingDataView()
            case .reading:
                BrowserTab().environmentObject(browser)
                    .withHostingWindow { window in
//                        if let windowNumber = window?.windowNumber {
//                            browser.restoreByWindowNumber(windowNumber: windowNumber,
//                                                          urlToTabIdConverter: navigation.tabIDFor(url:))
//                        } else {
                            if FeatureFlags.hasLibrary == false {
                                browser.loadMainArticle()
                            }
//                        }
                    }
            case .bookmarks:
                Bookmarks()
            case .opened:
                ZimFilesOpened(dismiss: nil).modifier(LibraryZimFileDetailSidePanel())
            case .categories:
                ZimFilesCategories(dismiss: nil).modifier(LibraryZimFileDetailSidePanel())
            case .downloads:
                ZimFilesDownloads(dismiss: nil).modifier(LibraryZimFileDetailSidePanel())
            case .new:
                ZimFilesNew(dismiss: nil).modifier(LibraryZimFileDetailSidePanel())
            default:
                EmptyView()
            }
        }
        .frame(minWidth: 650, minHeight: 500)
        .focusedSceneValue(\.navigationItem, $navigation.currentItem)
        .modifier(AlertHandler())
        .modifier(OpenFileHandler())
        .modifier(SaveContentHandler())
        .environmentObject(navigation)
        .onOpenURL { url in
            if url.isFileURL {
                NotificationCenter.openFiles([url], context: .file)
            } else if url.isZIMURL {
                NotificationCenter.openURL(url, navigationID: navigation.uuid)
            }
        }
        .onReceive(openURL) { notification in
            debugPrint("received openURL from: \(notification) for: \(navigation.uuid)")
            guard let url = notification.userInfo?["url"] as? URL,
                  let navID = notification.userInfo?["navigationID"] as? UUID,
                  navigation.uuid == navID else {
                return
            }
            if notification.userInfo?["isFileContext"] as? Bool == true {
                // handle the opened ZIM file from Finder
                // for which the system opens a new window,
                // this part of the code, will be called on all possible windows, we need this though,
                // otherwise it won't fire on app start, where we might not have a fully configured window yet.
                // We need to filter it down the the last window 
                // (which is usually not the key window yet at this point),
                // and load the content only within that
                Task {
                    if windowTracker.isLastWindow() {
                        browser.load(url: url)
                    }
                }
                return
            }
            guard controlActiveState == .key else { return }
            navigation.currentItem = .reading
            browser.load(url: url)
        }
        .onReceive(tabCloses) { publisher in
            // closing one window either by CMD+W || red(X) close button
            guard windowTracker.current == publisher.object as? NSWindow else {
                // when exiting full screen video, we get the same notification
                // but that's not comming from our window
                return
            }
            guard !navigation.isTerminating else {
                // tab closed by app termination
                return
            }
            if let tabID = browser.tabID {
                // tab closed by user
                browser.pauseVideoWhenNotInPIP()
                Task { @MainActor in
                    await browser.clear()
                }
                navigation.deleteTab(tabID: tabID)
            }
        }
        .onReceive(closeZimPublisher) { notification in
            browserClearModel.recievedClearZimFile(notification: notification, forBrowser: browser)
        }
        .onReceive(appTerminates) { _ in
            // CMD+Q -> Quit Kiwix, this also closes the last window
            navigation.isTerminating = true
        }.task {
            switch AppType.current {
            case .kiwix:
                await LibraryOperations.reopen()
                navigation.currentItem = .reading
                LibraryOperations.scanDirectory(URL.documentDirectory)
                LibraryOperations.applyFileBackupSetting()
                DownloadService.shared.restartHeartbeatIfNeeded()
            case let .custom(zimFileURL):
                await LibraryOperations.open(url: zimFileURL)
                ZimMigration.forCustomApps()
                navigation.currentItem = .reading
            }
            // MARK: - migrations
            if !ProcessInfo.processInfo.arguments.contains("testing") {
                _ = MigrationService().migrateAll()
            }
        }
        .withHostingWindow { [windowTracker] hostWindow in
            windowTracker.current = hostWindow
        }
    }
}

// MARK: helpers to capture the window

extension View {
    func withHostingWindow(_ callback: @escaping (NSWindow?) -> Void) -> some View {
        self.background(HostingWindowFinder(callback: callback))
    }
}

struct HostingWindowFinder: NSViewRepresentable {
    typealias NSViewType = NSView
    var callback: (NSWindow?) -> Void
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        Task { @MainActor [weak view] in
            self.callback(view?.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

#endif
