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

// swiftlint:disable:next type_body_length
struct RootView: View {
    @Environment(\.openWindow) var openWindow
    @Environment(\.controlActiveState) var controlActiveState
    @StateObject private var navigation = NavigationViewModel()
    @SceneStorage("org.kiwix.macos.root.menuitem") private var currentNavItem: MenuItem?
    @StateObject private var windowTracker = WindowTracker()
    @State private var paymentButtonLabel: PayWithApplePayButtonLabel?
    var isSearchFocused: FocusState<Bool>.Binding
    @StateObject private var selection = SelectedZimFileViewModel()
    // Open file alerts
    @State private var isOpenFileAlertPresented = false
    @State private var openFileAlert: OpenFileAlert?
    let openedWithWindowState: WindowState?
    
    private let primaryItems: [MenuItem] = [.bookmarks]
    private let libraryItems: [MenuItem] = [.opened, .categories, .downloads, .new]
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
                        ForEach(libraryItems + [MenuItem.hotspot], id: \.self) { menuItem in
                            Label(menuItem.name, systemImage: menuItem.icon)
                        }
                    }
                } else {
                    Label(MenuItem.hotspot.name, systemImage: MenuItem.hotspot.icon).id(MenuItem.hotspot)
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
                HotspotZimFilesSelection()
            default:
                EmptyView()
            }
        }
        .frame(minWidth: 650, minHeight: 500)
        .focusedSceneValue(\.navigationItem, $navigation.currentItem)
        .modifier(AlertHandler())
        .modifier(QuestionHandler())
        .modifier(OpenFileHandler())
        .modifier(SaveContentHandler())
        .environmentObject(navigation)
        .onChange(of: currentNavItem) { _, newValue in
            navigation.currentItem = newValue?.navigationItem
            saveSelectionInSession()
        }
        .onChange(of: navigation.currentItem) { _, newValue in
            guard let newValue else { return }
            let navItem = MenuItem(from: newValue)
            if currentNavItem != navItem {
                currentNavItem = navItem
            }
        }
        .onOpenURL { (url: URL) in
            /// if the app was just started via URL or file (wasn't open before)
            /// we want to load the content in the first window
            /// otherwise in a new tab (but within the currently active window)
            let isAppStart: Bool = NSApplication.shared.windows.count == 1
            if url.isFileURL {
                // from opening an external file
                let browser = BrowserViewModel.getCached(tabID: navigation.currentTabId)
                if isAppStart {
                    browser.forceLoadingState()
                }
                Task { // open the ZIM file
                    if let metadata: ZimFileMetaStruct = await LibraryOperations.open(url: url),
                       let mainPageURL: URL = await ZimFileService.shared.getMainPageURL(zimFileID: metadata.fileID) {
                        if isAppStart {
                            browser.load(url: mainPageURL)
                        } else {
                            browser.createNewWindow(with: mainPageURL)
                        }
                    } else {
                        await browser.clear()
                        isOpenFileAlertPresented = true
                        openFileAlert = OpenFileAlert.unableToOpen(filenames: [url.lastPathComponent])
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
            defer {
                windowTracker.current = nil // remove the reference to this window, see guard above
            }
            
            guard !navigation.isTerminating else {
                // tab closed by app termination
                return
            }
            let tabID = navigation.currentTabId
            let browser = BrowserViewModel.getCached(tabID: tabID)
            // tab closed by user
            browser.pauseVideoWhenNotInPIP()
            let currentWindow = windowTracker.current
            Task { [weak navigation] in
                await navigation?.deleteTab(tabID: tabID)
                if let currentWindow {
                    SessionRestore.shared.didClose(window: currentWindow)
                }
            }
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
        }.onReceive(goBackPublisher) { [weak navigation] _ in
            guard case .tab(let tabID) = navigation?.currentItem else {
                return
            }
            BrowserViewModel.getCached(tabID: tabID).webView.goBack()
        }.task {
            switch AppType.current {
            case .kiwix:
                await LibraryOperations.reValidate()
                restoreNavigationState()
                LibraryOperations.applyFileBackupSetting()
                DownloadService.shared.restartHeartbeatIfNeeded()
            case let .branded(zimFileURL):
                await LibraryOperations.open(url: zimFileURL)
                await ZimMigration.forCustomApps()
                restoreNavigationState()
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
        // Handle re-appearance and marking missing zim files
        .onChange(of: controlActiveState) { _, newState in
            switch newState {
            case .key:
                if FeatureFlags.hasLibrary {
                    Task {
                        await LibraryOperations.reValidate()
                        await navigation.deleteTabsWithMissingZimFiles()
                    }
                }
            case .active, .inactive:
                break
            @unknown default:
                break
            }
        }
        // special hook to trigger the zim file search in the nav bar, when a web view is opened
        // and the cmd+f is triggering the search in page
        .onReceive(NotificationCenter.default.publisher(for: .zimSearch)) { _ in
            isSearchFocused.wrappedValue = true
        }
        .withHostingWindow { [weak windowTracker] hostWindow in
            windowTracker?.current = hostWindow
            restoreWindow()
            saveSelectionInSession()
        }
        .handlesExternalEvents(
            preferring: Set([Self.zimURL]),
            allowing: Set([Self.zimURL, "file:///"])
        )
    }
    
    private func restoreNavigationState() {
        if let openedWithWindowState {
            if let restoredURL = URL(string: openedWithWindowState.menuItemId) {
                currentNavItem = MenuItem(rawValue: restoredURL.absoluteString)
                Log.SessionRestore.debug("restored on demand")
            }
            restoreWindow()
        }
        if currentNavItem == nil {
            // only set it if we are not restoring any previous state at start
            currentNavItem = .tab(objectID: navigation.currentTabId)
        }
    }
    
    private func restoreWindow() {
        guard let window = windowTracker.current, let savedState = openedWithWindowState else {
            return
        }
        // restore the window's identifier
        window.setAccessibilityIdentifier(savedState.identifier)
        window.setFrame(savedState.frame, display: true)
        
        // arrange the tabs
        if let tabIndex = savedState.tabIndex, tabIndex > 0 {
            let previousTabId = savedState.otherTabIds[tabIndex - 1]
            if let previousTab = NSApplication.shared.windows.first(where: { window in
                return window.accessibilityIdentifier() == previousTabId
            }) {
                previousTab.addTabbedWindow(window, ordered: .above)
            }
        }
        
        // once we created all tabs for this window tabgroup
        if savedState.isLastTab {
            // select the right tab
            if let selectedTabId = savedState.selectedTabId {
                window.tabGroup?.selectedWindow = NSApplication.shared.windows.first(where: { window in
                    window.accessibilityIdentifier() == selectedTabId
                })
            }
            // select the right window
            if let keyWindowId = savedState.keyWindowId {
                let nsWindow = NSApplication.shared.windows.first { $0.accessibilityIdentifier() == keyWindowId }
                nsWindow?.makeKey()
            }
        }
    }
    
    private func saveSelectionInSession() {
        guard let currentWindow = windowTracker.current, let currentNavItem else {
            return
        }
        SessionRestore.shared.didChangeMenuItem(currentNavItem, inWindow: currentWindow)
    }
}

#endif
