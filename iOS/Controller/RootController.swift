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
    let sideBarController = SideBarController()
    let contentController = ContentController()
    private var sideBarDisplayModeObserver: DefaultsObservation?
    private var masterIsVisible: Bool {
        get {
            return displayMode == .allVisible || displayMode == .primaryOverlay
        }
    }
    
    // MARK: - init & override

    init() {
        super.init(nibName: nil, bundle: nil)

        viewControllers = [sideBarController, UINavigationController(rootViewController: contentController)]
        delegate = self
        if #available(iOS 13.0, *) {
            primaryBackgroundStyle = .sidebar
            preferredDisplayMode = .primaryHidden
        }

        sideBarController.favoriteController.delegate = contentController
        sideBarController.outlineController.delegate = contentController
        contentController.configureToolbar(isGrouped: !isCollapsed)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.gestureRecognizers?.first?.delegate = self
        if UIDevice.current.userInterfaceIdiom == .pad {
            sideBarDisplayModeObserver = Defaults.observe(.sideBarDisplayMode) { change in
                guard self.masterIsVisible else { return }
                self.preferredDisplayMode = self.getPrimaryVisibleDisplayMode()
            }
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
        /*
         Hack: this function is called when user click the home button with wrong splitViewController.displayMode.
         To mitigate, check if the app is in background before do any UI adjustments.
         */
        guard UIApplication.shared.applicationState != .background else { return }
        if masterIsVisible && UIDevice.current.userInterfaceIdiom == .pad {
            preferredDisplayMode = getPrimaryVisibleDisplayMode(size: size)
        }
    }
    
    // MARK: - Utilities

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
        return sideBarController
    }

    func primaryViewController(forCollapsing splitViewController: UISplitViewController) -> UIViewController? {
        contentController.configureToolbar(isGrouped: false)
        contentController.dismissPopoverController()
        let navigationController = UINavigationController(rootViewController: contentController)
        navigationController.isToolbarHidden = contentController.searchController.isActive
        return navigationController
    }

    func splitViewController(_ splitViewController: UISplitViewController,
                             separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        contentController.configureToolbar(isGrouped: true)
        contentController.dismissPopoverController()
        let navigationController = UINavigationController(rootViewController: contentController)
        navigationController.isToolbarHidden = contentController.searchController.isActive
        return navigationController
    }

    // MARK: - UIGestureRecognizerDelegate

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // prevent the master controller from being displayed vie gesture when search is active
        guard !contentController.searchController.isActive else { return false }
        
        /*
         HACK: prevent UISplitViewController's build in gesture to work when the pan gesture's starting point
         is within 30 point of the left edge, so that the screen edge gesture in WKWebview can work.
        */
        return gestureRecognizer.location(in: view).x > 30
    }

    // MARK: - Actions
    
    func toggleSideBar() {
        preferredDisplayMode = masterIsVisible ? .primaryHidden : getPrimaryVisibleDisplayMode()
    }

    func openKiwixURL(_ url: URL) {
        guard url.isKiwixURL else {return}
        contentController.load(url: url)
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
            contentController.searchController.isActive = true
        case .bookmark:
            contentController.openBookmark()
        }
    }
}
