//
//  RootController.swift
//  Kiwix for iOS
//
//  Created by Chris Li on 11/24/19.
//  Copyright © 2019 Chris Li. All rights reserved.
//

import UIKit
import Defaults

class RootController: UISplitViewController, UISplitViewControllerDelegate, UIGestureRecognizerDelegate {
    let sideBarViewController = SideBarController()
    let contentViewController = ContentController()
    private var sideBarDisplayModeObserver: DefaultsObservation?
    
    var masterIsVisible: Bool {
        get {
            return displayMode == .allVisible || displayMode == .primaryOverlay
        }
    }

    init() {
        super.init(nibName: nil, bundle: nil)

        let navigationController = UINavigationController(rootViewController: contentViewController)
        navigationController.isToolbarHidden = false
        viewControllers = [sideBarViewController, navigationController]
        delegate = self
        if #available(iOS 13.0, *) { preferredDisplayMode = .primaryHidden }

        sideBarViewController.favoriteController.delegate = contentViewController
        sideBarViewController.outlineController.delegate = contentViewController
        contentViewController.configureToolbar(isGrouped: !isCollapsed)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.gestureRecognizers?.first?.delegate = self
        sideBarDisplayModeObserver = Defaults.observe(.sideBarDisplayMode) { change in
            guard self.masterIsVisible else { return }
            self.preferredDisplayMode = self.getPrimaryVisibleDisplayMode()
        }
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

        let shouldMasterBeVisible = masterIsVisible && traitCollection.horizontalSizeClass == .regular
        preferredDisplayMode = shouldMasterBeVisible ? getPrimaryVisibleDisplayMode(size: size) : .primaryHidden
    }

    func toggleSideBar() {
        preferredDisplayMode = masterIsVisible ? .primaryHidden : getPrimaryVisibleDisplayMode()
    }

    private func getPrimaryVisibleDisplayMode(size: CGSize? = nil) -> UISplitViewController.DisplayMode {
        switch Defaults[.sideBarDisplayMode] {
        case .automatic:
            let size = size ?? view.frame.size
            return size.width > size.height ? .allVisible : .primaryOverlay
        case .overlay:
            return .primaryOverlay
        case .sideBySide:
            return .allVisible
        }
    }

    // MARK: - UISplitViewControllerDelegate

    func primaryViewController(forExpanding splitViewController: UISplitViewController) -> UIViewController? {
        return sideBarViewController
    }

    func primaryViewController(forCollapsing splitViewController: UISplitViewController) -> UIViewController? {
        contentViewController.configureToolbar(isGrouped: false)
        contentViewController.dismissPopoverController()
        let navigationController = UINavigationController(rootViewController: contentViewController)
        navigationController.isToolbarHidden = contentViewController.searchController.isActive
        return navigationController
    }

    func splitViewController(_ splitViewController: UISplitViewController,
                             separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        contentViewController.configureToolbar(isGrouped: true)
        contentViewController.dismissPopoverController()
        let navigationController = UINavigationController(rootViewController: contentViewController)
        navigationController.isToolbarHidden = contentViewController.searchController.isActive
        return navigationController
    }

    // MARK: - UIGestureRecognizerDelegate

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        /*
         HACK: prevent UISplitViewController's build in gesture to work when the pan gesture's starting point
         is within 30 point of the left edge, so that the screen edge gesture in WKWebview can work.
        */
        return gestureRecognizer.location(in: view).x > 30
    }

    // MARK: Actions

    func openKiwixURL(_ url: URL) {
        guard url.isKiwixURL else {return}
        contentViewController.load(url: url)
    }

    func openFileURL(_ url: URL, canOpenInPlace: Bool) {
        guard url.isFileURL else {return}
        dismiss(animated: false)
        if ZimMultiReader.getMetaData(url: url) != nil {
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
