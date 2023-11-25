//
//  SplitViewController.swift
//  Kiwix
//
//  Created by Chris Li on 9/4/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

#if os(iOS)
import Combine
import SwiftUI
import UIKit

final class SplitViewController: UISplitViewController {
    let navigationViewModel: NavigationViewModel
    private var navigationItemObserver: AnyCancellable?
    private var openURLObserver: NSObjectProtocol?
    private var toggleSidebarObserver: NSObjectProtocol?
    
    init(navigationViewModel: NavigationViewModel) {
        self.navigationViewModel = navigationViewModel
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
        if #available(iOS 16.0, *) {} else {
            presentsWithGesture = false
        }
        
        // setup controllers
        setViewController(UINavigationController(rootViewController: CompactViewController()), for: .compact)
        setViewController(SidebarViewController(), for: .primary)
        setSecondaryController()

        // observers
        navigationItemObserver = navigationViewModel.$currentItem
            .receive(on: DispatchQueue.main)  // needed to postpones sink after navigationViewModel.currentItem updates
            .dropFirst()
            .sink { [weak self] _ in
                if let sidebarViewController = self?.viewController(for: .primary) as? SidebarViewController {
                    sidebarViewController.updateSelection()
                }
                if self?.traitCollection.horizontalSizeClass == .regular {
                    self?.setSecondaryController()
                }
            }
        openURLObserver = NotificationCenter.default.addObserver(
            forName: .openURL, object: nil, queue: nil
        ) { [weak self] notification in
            guard let url = notification.userInfo?["url"] as? URL else { return }
            let inNewTab = notification.userInfo?["inNewTab"] as? Bool ?? false
            if !inNewTab, case let .tab(tabID) = self?.navigationViewModel.currentItem {
                BrowserViewModel.getCached(tabID: tabID).load(url: url)
            } else {
                guard let tabID = self?.navigationViewModel.createTab() else { return }
                BrowserViewModel.getCached(tabID: tabID).load(url: url)
            }
        }
        toggleSidebarObserver = NotificationCenter.default.addObserver(
            forName: .toggleSidebar, object: nil, queue: nil
        ) { [weak self] _ in
            if #available(iOS 16.0, *) {} else {
                if self?.displayMode == .secondaryOnly {
                    self?.show(.primary)
                } else {
                    self?.hide(.primary)
                }
            }
        }
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
        guard previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass else { return }
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
            let view = BrowserTab().environmentObject(BrowserViewModel.getCached(tabID: tabID))
            let controller = UIHostingController(rootView: view)
            controller.navigationItem.scrollEdgeAppearance = {
                let apperance = UINavigationBarAppearance()
                apperance.configureWithDefaultBackground()
                return apperance
            }()
            setViewController(UINavigationController(rootViewController: controller), for: .secondary)
        case .opened:
            let controller = UIHostingController(rootView: ZimFilesOpened())
            setViewController(UINavigationController(rootViewController: controller), for: .secondary)
        case .categories:
            let controller = UIHostingController(rootView: ZimFilesCategories())
            setViewController(UINavigationController(rootViewController: controller), for: .secondary)
        case .downloads:
            let controller = UIHostingController(rootView: ZimFilesDownloads())
            setViewController(UINavigationController(rootViewController: controller), for: .secondary)
        case .new:
            let controller = UIHostingController(rootView: ZimFilesNew())
            setViewController(UINavigationController(rootViewController: controller), for: .secondary)
        case .settings:
            let controller = UIHostingController(rootView: Settings())
            setViewController(UINavigationController(rootViewController: controller), for: .secondary)
        case .loading:
            let controller = UIHostingController(rootView: Text("Loading..."))
            setViewController(UINavigationController(rootViewController: controller), for: .secondary)
        default:
            let controller = UIHostingController(rootView: Text("Not yet implemented"))
            setViewController(UINavigationController(rootViewController: controller), for: .secondary)
        }
    }
}
#endif
