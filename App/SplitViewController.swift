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

#if os(iOS)
import Combine
import SwiftUI
import UIKit

final class SplitViewController: UISplitViewController {
    let navigationViewModel: NavigationViewModel
    private var navigationItemObserver: AnyCancellable?
    private var showDownloadsObserver: AnyCancellable?
    private var openURLObserver: NSObjectProtocol?
    private var hasZimFiles: Bool
    private var isForegrounded: Bool = true
    var cancellables = Set<AnyCancellable>()

    init(
        navigationViewModel: NavigationViewModel,
        hasZimFiles: Bool
    ) {
        self.navigationViewModel = navigationViewModel
        self.hasZimFiles = hasZimFiles
        super.init(style: .doubleColumn)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // start with collapsed state for .loading
        preferredDisplayMode = .secondaryOnly

        // setup controllers
        setViewController(
            UINavigationController(
                rootViewController: CompactViewController(navigation: navigationViewModel)
            ),
            for: .compact
        )
        setViewController(SidebarViewController(), for: .primary)
        setSecondaryController()

        // observers
        observeNavigation()
        observeOpeningFiles()
        observeGoBackAndForward()
        observeAppBackgrounding()
    }
    
    private func observeNavigation() {
        navigationItemObserver = navigationViewModel.$currentItem
            .receive(on: DispatchQueue.main)  // needed to postpones sink after navigationViewModel.currentItem updates
            .dropFirst()
            .sink { [weak self] currentItem in
                if let sidebarViewController = self?.viewController(for: .primary) as? SidebarViewController {
                    sidebarViewController.updateSelection()
                }
                if self?.traitCollection.horizontalSizeClass == .regular {
                    self?.setSecondaryController()
                }
                if self?.hasZimFiles == true, currentItem != .loading {
                    self?.preferredDisplayMode = .automatic
                }
            }
        showDownloadsObserver = navigationViewModel.showDownloads
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                if self?.traitCollection.horizontalSizeClass == .regular,
                   self?.navigationViewModel.currentItem != .downloads {
                        self?.navigationViewModel.currentItem = .downloads
                }
                // the compact one is triggered in CompactViewController
        })
    }
    
    private func observeOpeningFiles() {
        openURLObserver = NotificationCenter.default.addObserver(
            forName: .openURL, object: nil, queue: .main
        ) { [weak self] notification in
            guard let url = notification.userInfo?["url"] as? URL else { return }
            let inNewTab = notification.userInfo?["inNewTab"] as? Bool ?? false
            Task { @MainActor [weak self] in
                if !inNewTab, case let .tab(tabID) = self?.navigationViewModel.currentItem {
                    BrowserViewModel.getCached(tabID: tabID).load(url: url)
                } else if let tabID = self?.navigationViewModel.createTab() {
                    BrowserViewModel.getCached(tabID: tabID).load(url: url)
                }
                if let context = notification.userInfo?["context"] as? OpenURLContext,
                   case .deepLink(.some(let deepLinkId)) = context {
                    DeepLinkService.shared.stopFor(uuid: deepLinkId)
                }
            }
        }
    }
    
    private func observeGoBackAndForward() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.publisher(for: .goBack)
            .sink { [weak self] _ in
                guard case .tab(let tabID) = self?.navigationViewModel.currentItem else {
                    return
                }
                BrowserViewModel.getCached(tabID: tabID).webView.goBack()
            }.store(in: &cancellables)
        notificationCenter.publisher(for: .goForward)
            .sink { [weak self] _ in
                guard case .tab(let tabID) = self?.navigationViewModel.currentItem else {
                    return
                }
                BrowserViewModel.getCached(tabID: tabID).webView.goForward()
            }.store(in: &cancellables)
    }
    
    private func observeAppBackgrounding() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.publisher(for: UIApplication.willEnterForegroundNotification, object: nil)
            .sink { [weak self] _ in
                self?.isForegrounded = true
            }.store(in: &cancellables)
        notificationCenter.publisher(for: UIApplication.didEnterBackgroundNotification, object: nil)
            .sink { [weak self] _ in
                self?.isForegrounded = false
            }.store(in: &cancellables)
    }

    /// Dismiss any controller that is already presented when horizontal size class is about to change
    override func willTransition(to newCollection: UITraitCollection,
                                 with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        guard newCollection.horizontalSizeClass != traitCollection.horizontalSizeClass else { return }
        presentedViewController?.dismiss(animated: false)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard isForegrounded,
              previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass else { return }
        if traitCollection.horizontalSizeClass == .compact {
            navigationViewModel.navigateToMostRecentTab()
        } else {
            setSecondaryController()
        }
    }

    private func setSecondaryController() {
        switch navigationViewModel.currentItem {
        case .bookmarks:
            let controller = UIHostingController(rootView: Bookmarks())
            setViewController(UINavigationController(rootViewController: controller), for: .secondary)
        case .tab(let tabID):
            let view = BrowserTab(tabID: tabID)
            let controller = UIHostingController(rootView: view)
            controller.navigationItem.scrollEdgeAppearance = {
                let apperance = UINavigationBarAppearance()
                apperance.configureWithDefaultBackground()
                return apperance
            }()
            setViewController(UINavigationController(rootViewController: controller), for: .secondary)
        case .opened:
            // workaround for programatic triggering ZimFileDetails
            // on iPad full screen view
            let navHelper = NavigationHelper()
            let controller = UIHostingController(rootView: ZimFilesOpened(navigationHelper: navHelper, dismiss: nil))
            let navController = UINavigationController(rootViewController: controller)
            navHelper.navigationController = navController
            setViewController(navController, for: .secondary)
        case .categories:
            let controller = UIHostingController(rootView: ZimFilesCategories(dismiss: nil))
            setViewController(UINavigationController(rootViewController: controller), for: .secondary)
        case .downloads:
            let controller = UIHostingController(
                rootView: ZimFilesDownloads(dismiss: nil)
                    .environment(\.managedObjectContext, Database.shared.viewContext)
            )
            setViewController(UINavigationController(rootViewController: controller), for: .secondary)
        case .new:
            let controller = UIHostingController(rootView: ZimFilesNew(dismiss: nil))
            setViewController(UINavigationController(rootViewController: controller), for: .secondary)
        case .settings:
            let controller = UIHostingController(rootView: Settings())
            setViewController(UINavigationController(rootViewController: controller), for: .secondary)
        case .loading:
            let controller = UIHostingController(rootView: LoadingDataView())
            setViewController(UINavigationController(rootViewController: controller), for: .secondary)
        case .hotspot:
            let controller = UIHostingController(rootView: HotspotZimFilesSelection())
            setViewController(UINavigationController(rootViewController: controller), for: .secondary)
        default:
            let controller = UIHostingController(rootView: Text("vc-not-implemented"))
            setViewController(UINavigationController(rootViewController: controller), for: .secondary)
        }
    }
}
#endif
