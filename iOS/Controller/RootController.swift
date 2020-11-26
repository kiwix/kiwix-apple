//
//  RootController.swift
//  Kiwix for iOS
//
//  Created by Chris Li on 11/24/19.
//  Copyright © 2019 Chris Li. All rights reserved.
//

import SwiftUI
import UIKit
import Defaults

class RootController: UISplitViewController, UISplitViewControllerDelegate, UIGestureRecognizerDelegate,
                      OutlineControllerDelegate, BookmarkControllerDelegate, WebViewControllerDelegate {
    
    // MARK: Controllers
    
    let sideBarController = UITabBarController()
    let bookmarksController = BookmarksController()
    let outlineController = OutlineController()
    private var secondaryController: UINavigationController
    private let contentController = ContentController()
    let webViewController = WebViewController()
    private var libraryController: LibraryController?
    
    // MARK: Buttons
    
    private let sideBarButton = BarButton(imageName: "sidebar.left")
    private let chevronLeftButton = BarButton(imageName: "chevron.left")
    private let chevronRightButton = BarButton(imageName: "chevron.right")
    private let outlineButton = BarButton(imageName: "list.bullet")
    private let bookmarkButton = BookmarkButton(imageName: "star", bookmarkedImageName: "star.fill")
    private let bookmarkToggleButton = BookmarkButton(imageName: "star.circle.fill", bookmarkedImageName: "star.circle")
    private let libraryButton = BarButton(imageName: "folder")
    private let settingButton = BarButton(imageName: "gear")
    private let bookmarkLongPressGestureRecognizer = UILongPressGestureRecognizer()
    
    // MARK: Other Properties
    
    private var sideBarDisplayModeObserver: DefaultsObservation?
    private var masterIsVisible: Bool {
        get {
            return displayMode == .allVisible || displayMode == .primaryOverlay
        }
    }
    
    // MARK: - Init & Override

    init() {
        sideBarController.viewControllers = [
            UINavigationController(rootViewController: bookmarksController),
            UINavigationController(rootViewController: outlineController),
        ]
        secondaryController = UINavigationController(rootViewController: contentController)
        secondaryController.isToolbarHidden = false
        super.init(nibName: nil, bundle: nil)

        // configuring splitView controlller
        delegate = self
        presentsWithGesture = false
        viewControllers = [sideBarController, secondaryController]
        if #available(iOS 13.0, *) { preferredDisplayMode = .primaryHidden }

        // set delegates
        webViewController.delegate = self
        bookmarksController.delegate = self
        outlineController.delegate = self
        
        // wire up button actions
        sideBarButton.addTarget(self, action: #selector(toggleSideBar), for: .touchUpInside)
        chevronLeftButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        chevronRightButton.addTarget(self, action: #selector(goForward), for: .touchUpInside)
        outlineButton.addTarget(self, action: #selector(openOutline), for: .touchUpInside)
        libraryButton.addTarget(self, action: #selector(openLibrary), for: .touchUpInside)
        settingButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        bookmarkButton.addTarget(self, action: #selector(openBookmark), for: .touchUpInside)
        bookmarkToggleButton.addTarget(self, action: #selector(toggleBookmark), for: .touchUpInside)
        bookmarkButton.addGestureRecognizer(bookmarkLongPressGestureRecognizer)
        bookmarkLongPressGestureRecognizer.addTarget(self, action: #selector(toggleBookmark))
        
        // putting buttons into their spots
        configureBarButtons(isGrouped: !isCollapsed)
        updateBarButtons()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.gestureRecognizers?.first?.delegate = self
        if #available(iOS 13.0, *), UIDevice.current.userInterfaceIdiom == .pad {
            sideBarDisplayModeObserver = Defaults.observe(.sideBarDisplayMode, options: [.prior]) { change in
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
    
    // MARK: - Utilities
    
    private func configureBarButtons(isGrouped: Bool) {
        if isGrouped {
            let left = BarButtonGroup(buttons: [sideBarButton, chevronLeftButton, chevronRightButton], spacing: 10)
            let right = BarButtonGroup(buttons: [bookmarkToggleButton, libraryButton, settingButton], spacing: 10)
            contentController.toolbarItems = [
                UIBarButtonItem(customView: left),
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                UIBarButtonItem(customView: right),
            ]
        } else {
            let group = BarButtonGroup(buttons: [
                chevronLeftButton, chevronRightButton, outlineButton, bookmarkButton, libraryButton, settingButton,
            ])
            contentController.toolbarItems = [UIBarButtonItem(customView: group)]
        }
    }
    
    private func updateBarButtons(isBookmarked: Bool? = nil) {
        chevronLeftButton.isEnabled = webViewController.canGoBack
        chevronRightButton.isEnabled = webViewController.canGoForward
        outlineButton.isEnabled = webViewController.currentURL != nil
        if let isBookmarked = isBookmarked {
            bookmarkButton.isBookmarked = isBookmarked
            bookmarkToggleButton.isBookmarked = isBookmarked
        } else if let url = webViewController.currentURL, let _ = BookmarkService().get(url: url) {
            bookmarkToggleButton.isEnabled = true
            bookmarkButton.isBookmarked = true
            bookmarkToggleButton.isBookmarked = true
        } else if let _ = webViewController.currentURL {
            bookmarkToggleButton.isEnabled = true
            bookmarkButton.isBookmarked = false
            bookmarkToggleButton.isBookmarked = false
        } else {
            bookmarkToggleButton.isEnabled = false
        }
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
    
    private func presentBookmarkHUDController(isBookmarked: Bool) {
        let controller = HUDController()
        controller.modalPresentationStyle = .custom
        controller.transitioningDelegate = controller
        controller.direction = isBookmarked ? .down : .up
        controller.imageView.image = isBookmarked ? #imageLiteral(resourceName: "StarAdd") : #imageLiteral(resourceName: "StarRemove")
        controller.label.text = isBookmarked ?
            NSLocalizedString("Added", comment: "Bookmark HUD") :
            NSLocalizedString("Removed", comment: "Bookmark HUD")
        
        present(controller, animated: true, completion: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                controller.dismiss(animated: true, completion: nil)
            })
        })
    }

    // MARK: - UISplitViewControllerDelegate

    func primaryViewController(forExpanding splitViewController: UISplitViewController) -> UIViewController? {
        return sideBarController
    }

    func primaryViewController(forCollapsing splitViewController: UISplitViewController) -> UIViewController? {
        configureBarButtons(isGrouped: false)
        secondaryController = UINavigationController(rootViewController: contentController)
        secondaryController.isToolbarHidden = contentController.searchController.isActive
        return secondaryController
    }

    func splitViewController(_ splitViewController: UISplitViewController,
                             separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        configureBarButtons(isGrouped: true)
        secondaryController = UINavigationController(rootViewController: contentController)
        secondaryController.isToolbarHidden = contentController.searchController.isActive
        return secondaryController
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
    
    // MARK: - OutlineControllerDelegate
    
    func didTapOutlineItem(item: OutlineItem) {
        if contentController.searchController.isActive { contentController.searchController.isActive = false }
        webViewController.scrollToOutlineItem(index: item.index)
    }
    
    // MARK: - BookmarkControllerDelegate
    
    func didTapBookmark(url: URL) {
        if contentController.searchController.isActive { contentController.searchController.isActive = false }
        openKiwixURL(url)
    }
    
    func didDeleteBookmark(url: URL) {
        guard let rootController = splitViewController as? RootController,
              rootController.webViewController.currentURL?.absoluteURL == url.absoluteURL else {return}
        rootController.bookmarkButton.isBookmarked = false
        rootController.bookmarkToggleButton.isBookmarked = false
    }
    
    // MARK: - WebViewControllerDelegate
    
    func webViewDidTapOnGeoLocation(controller: WebViewController, url: URL) {
        
    }
    
    func webViewDidFinishNavigation(controller: WebViewController) {
        updateBarButtons()
        
        // update outline items if outline view is visible
        if !isCollapsed, displayMode != .primaryHidden {
            outlineController.update()
        }
    }

    // MARK: - Actions
    
    @objc func toggleSideBar() {
        UIView.animate(withDuration: 0.2) {
            self.preferredDisplayMode = self.masterIsVisible ? .primaryHidden : self.getPrimaryVisibleDisplayMode()
        }
    }
    
    @objc func goBack() {
        webViewController.goBack()
    }
    
    @objc func goForward() {
        webViewController.goForward()
    }
    
    @objc func openOutline() {
        let outlineController = OutlineController()
        let navigationController = UINavigationController(rootViewController: outlineController)
        outlineController.delegate = self
        present(navigationController, animated: true)
    }
    
    @objc func openBookmark() {
        let controller = BookmarksController()
        let navigationController = UINavigationController(rootViewController: controller)
        controller.delegate = self
        present(navigationController, animated: true)
    }
    
    @objc func toggleBookmark(sender: Any) {
        if let recognizer = sender as? UILongPressGestureRecognizer, recognizer.state != .began {
            return
        }
        
        guard let url = webViewController.currentURL else { return }
        let bookmarkService = BookmarkService()
        if let bookmark = bookmarkService.get(url: url) {
            bookmarkService.delete(bookmark)
            updateBarButtons(isBookmarked: false)
            presentBookmarkHUDController(isBookmarked: false)
        } else {
            bookmarkService.create(url: url)
            updateBarButtons(isBookmarked: true)
            presentBookmarkHUDController(isBookmarked: true)
        }
    }
    
    @objc func openLibrary() {
        if #available(iOS 14.0, *) {
            present(LibraryViewController_iOS14(), animated: true)
        } else {
            let libraryController = self.libraryController ?? LibraryController(onDismiss: {
                let timer = Timer(timeInterval: 60, repeats: false, block: { [weak self] timer in
                    self?.libraryController = nil
                })
                RunLoop.main.add(timer, forMode: .default)
            })
            self.libraryController = libraryController
            present(libraryController, animated: true)
        }
    }
    
    @objc func openSettings() {
        present(SettingNavigationController(), animated: true)
    }
    
    @objc func openTabsView() {
        present(TabsController(), animated: true)
    }
    
    func openMainPage(zimFileID: String) {
        guard let url = ZimMultiReader.shared.getMainPageURL(zimFileID: zimFileID) else { return }
        openKiwixURL(url)
    }

    func openKiwixURL(_ url: URL) {
        guard url.isKiwixURL else {return}
        webViewController.load(url: url)
        contentController.setChildControllerIfNeeded(webViewController)
        contentController.dismissSearch()
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
            openBookmark()
        }
    }
}
