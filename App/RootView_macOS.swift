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

#if os(macOS)
import SwiftUI
import PassKit

struct RootView: View {
    @Environment(\.openWindow) var openWindow
    @Environment(\.controlActiveState) var controlActiveState
    @StateObject private var navigation = NavigationViewModel()
    @State private var currentNavItem: MenuItem?
    @StateObject private var windowTracker = WindowTracker()
    @State private var paymentButtonLabel: PayWithApplePayButtonLabel?
    var isSearchFocused: FocusState<Bool>.Binding
    @StateObject private var selection = SelectedZimFileViewModel()
    // Open file alerts
    @State private var isOpenFileAlertPresented = false
    @State private var openFileAlert: OpenFileAlert?
    
    private let primaryItems: [MenuItem] = [.bookmarks]
    private let libraryItems: [MenuItem] = [.opened, .categories, .downloads, .new, .hotspot]
    private let openURL = NotificationCenter.default.publisher(for: .openURL)
    private let appTerminates = NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)
    private let tabCloses = NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)
    private let goBackPublisher = NotificationCenter.default.publisher(for: .goBack)
    private let goForwardPublisher = NotificationCenter.default.publisher(for: .goForward)
    /// Close other tabs then the ones received
    private let keepOnlyTabs = NotificationCenter.default.publisher(for: .keepOnlyTabs)
    // in essence it's the "zim://" value
    private static let zimURL: String = "\(KiwixURLSchemeHandler.ZIMScheme)://"

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
                    .modifier(SearchFocused(isSearchFocused: isSearchFocused))
            case .bookmarks:
                Bookmarks()
                    .modifier(SearchFocused(isSearchFocused: isSearchFocused))
            case .opened:
                ZimFilesMultiOpened()
            case .categories:
                DetailSidePanel(content: { ZimFilesCategories(dismiss: nil) })
                    .modifier(SearchFocused(isSearchFocused: isSearchFocused))
            case .downloads:
                DetailSidePanel(content: { ZimFilesDownloads(dismiss: nil) })
            case .new:
                DetailSidePanel(content: { ZimFilesNew(dismiss: nil) })
                    .modifier(SearchFocused(isSearchFocused: isSearchFocused))
            case .hotspot:
                ZimFilesMultiOpened()
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
        .onChange(of: navigation.currentItem) { newValue in
            guard let newValue else { return }
            let navItem = MenuItem(from: newValue)
            if currentNavItem != navItem {
                currentNavItem = navItem
            }
        }
        .onOpenURL { url in
            /// if the app was just started via URL or file (wasn't open before)
            /// we want to load the content in the first window
            /// otherwise in a new tab (but within the currently active window)
            let isAppStart = NSApplication.shared.windows.count == 1
            if url.isFileURL {
                // from opening an external file
                let browser = BrowserViewModel.getCached(tabID: navigation.currentTabId)
                if isAppStart {
                    browser.forceLoadingState()
                }
                Task { // open the ZIM file
                    if let metadata = await LibraryOperations.open(url: url),
                       let mainPageURL = await ZimFileService.shared.getMainPageURL(zimFileID: metadata.fileID) {
                        if isAppStart {
                            browser.load(url: mainPageURL)
                        } else {
                            browser.createNewWindow(with: mainPageURL)
                        }
                    } else {
                        await browser.clear()
                        isOpenFileAlertPresented = true
                        openFileAlert = .unableToOpen(filenames: [url.lastPathComponent])
                    }
                }
            } else if url.isZIMURL {
                // from deeplinks
                if isAppStart {
                    let browser = BrowserViewModel.getCached(tabID: navigation.currentTabId)
                    browser.load(url: url)
                } else {
                    Task { @MainActor in
                        // we want to open the deeplink a new tab (in the currently active window)
                        // at this point though, the latest tab is active, that received the deeplink handling
                        // therefore we do need to wait 1 UI cycle, to finish the original
                        // deeplink handling (hence the Task { @MainActor solution)
                        // This way we can activate the newly opened tab with the deeplink content in it
                        let browser = BrowserViewModel.getCached(tabID: navigation.currentTabId)
                        browser.createNewWindow(with: url)
                    }
                }
            }
        }
        .alert(LocalString.file_import_alert_no_open_title,
               isPresented: $isOpenFileAlertPresented, presenting: openFileAlert) { _ in
        } message: { alert in
            switch alert {
            case .unableToOpen(let filenames):
                let name = ListFormatter.localizedString(byJoining: filenames)
                Text(LocalString.file_import_alert_no_open_message(withArgs: name))
            }
        }
        .onReceive(openURL) { notification in
            guard let url = notification.userInfo?["url"] as? URL else {
                return
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
            windowTracker.current = nil // remove the reference to this window, see guard above
            
            guard !navigation.isTerminating else {
                // tab closed by app termination
                return
            }
            let tabID = navigation.currentTabId
            let browser = BrowserViewModel.getCached(tabID: tabID)
            // tab closed by user
            browser.pauseVideoWhenNotInPIP()
            navigation.deleteTab(tabID: tabID)
        }
        .onReceive(keepOnlyTabs) {notification in
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
        }.onReceive(goBackPublisher) { [weak navigation] _ in
            guard case .tab(let tabID) = navigation?.currentItem else {
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
        // special hook to trigger the zim file search in the nav bar, when a web view is opened
        // and the cmd+f is triggering the search in page
        .onReceive(NotificationCenter.default.publisher(for: .zimSearch)) { _ in
            isSearchFocused.wrappedValue = true
        }
        .withHostingWindow { [weak windowTracker] hostWindow in
            windowTracker?.current = hostWindow
        }
        .handlesExternalEvents(
            preferring: Set([Self.zimURL]),
            allowing: Set([Self.zimURL, "file:///"])
        )
    }
}

#endif
