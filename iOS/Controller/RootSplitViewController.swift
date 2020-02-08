//
//  RootSplitViewController.swift
//  Kiwix for iOS
//
//  Created by Chris Li on 11/24/19.
//  Copyright © 2019 Chris Li. All rights reserved.
//

import UIKit

class RootSplitViewController: UISplitViewController, UISplitViewControllerDelegate {
    let sideBarViewController = SideBarController()
    let contentViewController = ContentViewController()
    let contentNavigationController: UINavigationController
    
    init() {
        self.contentNavigationController = UINavigationController(rootViewController: contentViewController)
        self.contentNavigationController.isToolbarHidden = false
        
        super.init(nibName: nil, bundle: nil)
        viewControllers = [sideBarViewController, self.contentNavigationController]
        delegate = self
        
        /* For some reason, the sidebar is not rendered correctly if hidden on launch when running on iOS 12.
           Well, I guess the app is gonna launch with sidebar visible on iOS 12. */
        if #available(iOS 13.0, *) {
            preferredDisplayMode = .automatic
        } else {
            preferredDisplayMode = .allVisible
        }
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
        preferredDisplayMode = size.width > size.height ? .automatic : .primaryHidden
    }
    
    // MARK: UISplitViewControllerDelegate
    
    func primaryViewController(forExpanding splitViewController: UISplitViewController) -> UIViewController? {
        return sideBarViewController
    }
    
    func primaryViewController(forCollapsing splitViewController: UISplitViewController) -> UIViewController? {
        contentViewController.configureToolbar(isGrouped: false)
        return contentNavigationController
    }
    
    func splitViewController(_ splitViewController: UISplitViewController,
                             separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        contentViewController.configureToolbar(isGrouped: true)
        return contentNavigationController
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
