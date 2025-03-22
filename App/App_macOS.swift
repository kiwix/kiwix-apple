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
import PassKit

#if os(macOS)
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

@main
struct Kiwix: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) var openWindow
    @StateObject private var libraryRefreshViewModel = LibraryViewModel()
    private let notificationCenterDelegate = NotificationCenterDelegate()
    private var amountSelected = PassthroughSubject<SelectedAmount?, Never>()
    @State private var selectedAmount: SelectedAmount?
    @StateObject var formReset = FormReset()

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
                OpenFileButton(context: .command) { Text(LocalString.app_macos_commands_open_file) }
            }
            CommandGroup(replacing: .newItem) {
                Button(LocalString.app_macos_commands_new) {
                    guard let currentWindow = NSApp.keyWindow,
                          let controller = currentWindow.windowController else { return }
                    controller.newWindowForTab(nil)
                    guard let newWindow = NSApp.keyWindow, currentWindow != newWindow else { return }
                    currentWindow.addTabbedWindow(newWindow, ordered: .above)
                }.keyboardShortcut("t")
                Divider()
            }
            CommandGroup(after: .toolbar) {
                NavigationCommands(goBack: {
                    NotificationCenter.default.post(name: .goBack, object: nil)
                }, goForward: {
                    NotificationCenter.default.post(name: .goForward, object: nil)
                })
                Divider()
                PageZoomCommands()
                Divider()
                SidebarNavigationCommands()
                Divider()
            }
            CommandGroup(replacing: .help) {}
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
        Window(LocalString.payment_donate_title, id: "donation") {
            Group {
                if let selectedAmount {
                    PaymentSummary(selectedAmount: selectedAmount, onComplete: {
                        closeDonation()
                        switch Payment.showResult() {
                        case .none: break
                        case .thankYou:
                            openWindow(id: "donation-thank-you")
                        case .error:
                            openWindow(id: "donation-error")
                        }
                    })
                } else {
                    PaymentForm(amountSelected: amountSelected)
                        .frame(width: 320, height: 320)
                }
            }
            .onReceive(amountSelected) { amount in
                selectedAmount = amount
            }
            .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { notification in
                if let window = notification.object as? NSWindow,
                   window.identifier?.rawValue == "donation" {
                    formReset.reset()
                    selectedAmount = nil
                }
            }
            .environmentObject(formReset)
        }
        .windowResizability(.contentMinSize)
        .windowStyle(.titleBar)
        .commandsRemoved()
        .defaultSize(width: 320, height: 400)

        Window("", id: "donation-thank-you") {
            PaymentResultPopUp(state: .thankYou)
                .padding()
        }
        .windowResizability(.contentMinSize)
        .commandsRemoved()
        .defaultSize(width: 320, height: 198)

        Window("", id: "donation-error") {
            PaymentResultPopUp(state: .error)
                .padding()
        }
        .windowResizability(.contentMinSize)
        .commandsRemoved()
        .defaultSize(width: 320, height: 198)
    }

    private func closeDonation() {
        // after upgrading to macOS 14, use:
        // @Environment(\.dismissWindow) var dismissWindow
        // and call:
        // dismissWindow(id: "donation")
        NSApplication.shared.windows.first { window in
            window.identifier?.rawValue == "donation"
        }?.close()
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
    @Environment(\.openWindow) var openWindow
    @Environment(\.controlActiveState) var controlActiveState
    @StateObject private var navigation = NavigationViewModel()
    @State private var currentNavItem: MenuItem?
    @StateObject private var windowTracker = WindowTracker()
    @State private var paymentButtonLabel: PayWithApplePayButtonLabel?

    private let primaryItems: [MenuItem] = [.bookmarks]
    private let libraryItems: [MenuItem] = [.opened, .categories, .downloads, .new]
    private let openURL = NotificationCenter.default.publisher(for: .openURL)
    private let appTerminates = NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)
    private let tabCloses = NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)
    private let goBackPublisher = NotificationCenter.default.publisher(for: .goBack)
    private let goForwardPublisher = NotificationCenter.default.publisher(for: .goForward)
    /// Close other tabs then the ones received
    private let keepOnlyTabs = NotificationCenter.default.publisher(for: .keepOnlyTabs)

    var body: some View {
        NavigationSplitView {
            List(selection: $currentNavItem) {
                ForEach(
                    [MenuItem.tab(objectID: navigation.currentTabId)] + primaryItems,
                    id: \.self
                ) { menuItem in
                    Label(menuItem.name, systemImage: menuItem.icon)
                }
                if FeatureFlags.hasLibrary {
                    Section(LocalString.app_macos_navigation_button_library) {
                        ForEach(libraryItems, id: \.self) { menuItem in
                            Label(menuItem.name, systemImage: menuItem.icon)
                        }
                    }
                }
            }
            .frame(minWidth: 160)
            .safeAreaInset(edge: .bottom) {
                if paymentButtonLabel != nil && Brand.hideDonation != true {
                    SupportKiwixButton {
                        openWindow(id: "donation")
                    }
                }
            }
        } detail: {
            switch navigation.currentItem {
            case .loading:
                LoadingDataView()
            case .tab(let tabID):
                BrowserTab(tabID: tabID)
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
        .onChange(of: currentNavItem) { newValue in
            navigation.currentItem = newValue?.navigationItem
        }
        .onOpenURL { url in
            if url.isFileURL {
                // from opening an external file
                let browser = BrowserViewModel.getCached(tabID: navigation.currentTabId)
                browser.forceLoadingState()
                NotificationCenter.openFiles([url], context: .file)
            } else if url.isZIMURL {
                // from deeplinks
                let browser = BrowserViewModel.getCached(tabID: navigation.currentTabId)
                browser.forceLoadingState()
                NotificationCenter.openURL(url, context: .deepLink)
            }
        }
        .onReceive(openURL) { notification in
            guard let url = notification.userInfo?["url"] as? URL else {
                return
            }
            switch notification.userInfo?["context"] as? OpenURLContext {
            case .file, .deepLink:
                // handle the opened ZIM file from Finder / DeepLink
                // for which the system opens a new window,
                // this part of the code, will be called on all possible windows, we need this though,
                // otherwise it won't fire on app start, where we might not have a fully configured window yet.
                // We need to filter it down the the last window
                // (which is usually not the key window yet at this point),
                // and load the content only within that
                Task { @MainActor [weak navigation] in
                    if windowTracker.isLastWindow(), let navigation {
                        BrowserViewModel.getCached(tabID: navigation.currentTabId).load(url: url)
                    }
                }
                return
                
            case .none:
                break
            }
            guard controlActiveState == .key else { return }
            let tabID = navigation.currentTabId
            currentNavItem = .tab(objectID: tabID)
            BrowserViewModel.getCached(tabID: tabID).load(url: url)
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
            let tabID = navigation.currentTabId
            let browser = BrowserViewModel.getCached(tabID: tabID)
            // tab closed by user
            browser.pauseVideoWhenNotInPIP()
            Task { @MainActor [weak browser] in
                await browser?.clear()
            }
            navigation.deleteTab(tabID: tabID)
        }
        .onReceive(keepOnlyTabs) { notification in
            guard let tabsToKeep = notification.userInfo?["tabIds"] as? Set<NSManagedObjectID> else {
                return
            }
            navigation.keepOnlyTabsBy(tabIds: tabsToKeep)
        }
        .onReceive(appTerminates) { _ in
            // CMD+Q -> Quit Kiwix, this also closes the last window
            navigation.isTerminating = true
        }.onReceive(goForwardPublisher) { _ in
            guard case .tab(let tabID) = navigation.currentItem else {
                return
            }
            BrowserViewModel.getCached(tabID: tabID).webView.goForward()
        }.onReceive(goBackPublisher) { _ in
            guard case .tab(let tabID) = navigation.currentItem else {
                return
            }
            BrowserViewModel.getCached(tabID: tabID).webView.goBack()
        }.task {
            switch AppType.current {
            case .kiwix:
                await LibraryOperations.reopen()
                currentNavItem = .tab(objectID: navigation.currentTabId)
                LibraryOperations.scanDirectory(URL.documentDirectory)
                LibraryOperations.applyFileBackupSetting()
                DownloadService.shared.restartHeartbeatIfNeeded()
            case let .custom(zimFileURL):
                await LibraryOperations.open(url: zimFileURL)
                ZimMigration.forCustomApps()
                currentNavItem = .tab(objectID: navigation.currentTabId)
            }
            // MARK: - payment button init
            if Brand.hideDonation == false {
                paymentButtonLabel = await Payment.paymentButtonTypeAsync()
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
