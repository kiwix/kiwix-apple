//
//  RootController.swift
//  Kiwix for iOS
//
//  Created by Chris Li on 11/24/19.
//  Copyright © 2019 Chris Li. All rights reserved.
//

import UIKit

class RootController: UISplitViewController, UISplitViewControllerDelegate {
    let sideBarViewController = SideBarController()
    let contentViewController = ContentViewController()
    
    init() {
        super.init(nibName: nil, bundle: nil)

        let navigationController = UINavigationController(rootViewController: contentViewController)
        navigationController.isToolbarHidden = false
        viewControllers = [sideBarViewController, navigationController]
        delegate = self
        preferredDisplayMode = .primaryHidden

        sideBarViewController.favoriteController.delegate = contentViewController
        sideBarViewController.outlineController.delegate = contentViewController
        contentViewController.configureToolbar(isGrouped: !isCollapsed)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func overrideTraitCollection(forChild childViewController: UIViewController) -> UITraitCollection? {
        if viewControllers.count > 1,
            childViewController == viewControllers.last,
            displayMode == .allVisible {
            return UITraitCollection(horizontalSizeClass: .compact)
        } else {
            return super.overrideTraitCollection(forChild: childViewController)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        let masterIsVisible = displayMode == .allVisible || displayMode == .primaryOverlay
        let shouldMasterBeVisible = masterIsVisible && traitCollection.horizontalSizeClass == .regular
        preferredDisplayMode = shouldMasterBeVisible ? getPrimaryVisibleDisplayMode(size: size) : .primaryHidden
    }
    
    func toggleSideBar() {
        let masterIsVisible = displayMode == .allVisible || displayMode == .primaryOverlay
        preferredDisplayMode = masterIsVisible ? .primaryHidden : getPrimaryVisibleDisplayMode()
    }
    
    private func getPrimaryVisibleDisplayMode(size: CGSize? = nil) -> UISplitViewController.DisplayMode {
        let size = size ?? view.frame.size
        return size.width > size.height ? .allVisible : .primaryOverlay
    }
    
    // MARK: UISplitViewControllerDelegate
    
    func primaryViewController(forExpanding splitViewController: UISplitViewController) -> UIViewController? {
        return sideBarViewController
    }

    func primaryViewController(forCollapsing splitViewController: UISplitViewController) -> UIViewController? {
        contentViewController.configureToolbar(isGrouped: false)
        let navigationController = UINavigationController(rootViewController: contentViewController)
        navigationController.isToolbarHidden = false
        return navigationController
    }

    func splitViewController(_ splitViewController: UISplitViewController,
                             separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        contentViewController.configureToolbar(isGrouped: true)
        let navigationController = UINavigationController(rootViewController: contentViewController)
        navigationController.isToolbarHidden = false
        return navigationController
    }
    
    // MARK: Actions
    
    func openKiwixURL(_ url: URL) {
        guard url.isKiwixURL else {return}
        contentViewController.load(url: url)
    }
    
    func openFileURL(_ url: URL, canOpenInPlace: Bool) {
        guard url.isFileURL else {return}
        dismiss(animated: false)
        if let _ = ZimMultiReader.getMetaData(url: url) {
            let fileImportController = FileImportController(fileURL: url, canOpenInPlace: canOpenInPlace)
            present(fileImportController, animated: true)
        } else {
            present(FileImportAlertController(fileName: url.lastPathComponent), animated: true)
        }
    }
    
    func openShortcut(_ shortcut: Shortcut) {
        dismiss(animated: false)
        switch shortcut {
        case .search:
            contentViewController.searchController.isActive = true
        case .bookmark:
            contentViewController.openBookmark()
        }
    }
}
