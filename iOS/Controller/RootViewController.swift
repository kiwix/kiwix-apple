//
//  RootViewController.swift
//  Kiwix
//
//  Created by Chris Li on 11/28/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import SwiftUI
import UIKit
import WebKit
import SafariServices
import Defaults
import RealmSwift

class RootViewController: UIViewController, UISearchControllerDelegate, UISplitViewControllerDelegate, WKNavigationDelegate {
    let searchController: UISearchController
    fileprivate let searchResultsController: SearchResultsController
    fileprivate let contentViewController: UISplitViewController
    fileprivate let welcomeController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WelcomeController") as! WelcomeController
    fileprivate let webViewController = WebViewController()
    fileprivate var libraryController: LibraryController?
    
    fileprivate let onDeviceZimFiles = Queries.onDeviceZimFiles()?.sorted(byKeyPath: "size", ascending: false)
    fileprivate let buttonProvider: ButtonProvider
    
    // MARK: - Buttons
    
    fileprivate let diceButton = BarButton(imageName: "die.face.5")
    fileprivate let houseButton = BarButton(imageName: "house")
    fileprivate let libraryButton = BarButton(imageName: "folder")
    fileprivate let settingButton = BarButton(imageName: "gear")
    fileprivate let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
    
    fileprivate var navigationRightButtons: [BarButton] {
        [diceButton, houseButton, libraryButton, settingButton]
    }
    fileprivate var toolbarButtons: [BarButton] {
        [buttonProvider.chevronLeftButton, buttonProvider.chevronRightButton, buttonProvider.outlineButton, buttonProvider.bookmarkButton, libraryButton, settingButton]
    }
    
    // MARK: - Init & Overrides
    
    init(contentViewController: UISplitViewController = UISplitViewController()) {
        self.searchResultsController = SearchResultsController()
        self.searchController = UISearchController(searchResultsController: self.searchResultsController)
        self.contentViewController = contentViewController
        self.buttonProvider = ButtonProvider(webView: webViewController.webView)
        super.init(nibName: nil, bundle: nil)
        buttonProvider.rootViewController = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup button initial state
        configureBarButtons(searchIsActive: searchController.isActive, animated: false)
        
        // wire up button actions
        diceButton.addTarget(self, action: #selector(diceButtonTapped), for: .touchUpInside)
        houseButton.addTarget(self, action: #selector(houseButtonTapped), for: .touchUpInside)
        libraryButton.addTarget(self, action: #selector(openLibrary), for: .touchUpInside)
        settingButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        cancelButton.target = self
        cancelButton.action = #selector(dismissSearch)
        
        // configure content view controller as a child
        setupContentViewController()
        addChild(contentViewController)
        contentViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentViewController.view)
        if #available(iOS 13.0, *) {
            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: contentViewController.view.topAnchor),
                view.leftAnchor.constraint(equalTo: contentViewController.view.leftAnchor),
                view.bottomAnchor.constraint(equalTo: contentViewController.view.bottomAnchor),
                view.rightAnchor.constraint(equalTo: contentViewController.view.rightAnchor),
            ])
        } else {
            // on iOS 12, the contentViewController's master & detail controllers do not seem to be aware of the safe area,
            // so the contentViewController is going to be pinned against the safe area layout guide veritcally
            // and there won't be the content underneath the bar behavior
            view.backgroundColor = .white
            NSLayoutConstraint.activate([
                view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: contentViewController.view.topAnchor),
                view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: contentViewController.view.bottomAnchor),
                view.leftAnchor.constraint(equalTo: contentViewController.view.leftAnchor),
                view.rightAnchor.constraint(equalTo: contentViewController.view.rightAnchor),
            ])
        }
        contentViewController.didMove(toParent: self)
        
        // configure search controller
        searchController.delegate = self
        searchController.searchBar.autocorrectionType = .no
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.searchBarStyle = .minimal
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchResultsUpdater = searchResultsController
        if #available(iOS 13.0, *) {
            searchController.automaticallyShowsCancelButton = false
            searchController.showsSearchResultsController = true
        }
        definesPresentationContext = true
        
        // misc
        navigationItem.titleView = searchController.searchBar
        webViewController.webView.navigationDelegate = self
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        if newCollection.horizontalSizeClass == .regular {
            // dismiss presented outline and bookmark controller from when view was horizontally compact
            if let navigationController = presentedViewController as? UINavigationController,
               let topViewController = navigationController.topViewController,
               (topViewController is OutlineViewController || topViewController is BookmarksViewController) {
                presentedViewController?.dismiss(animated: false)
            }
            
            // hide sidebar when view transition to horizontally regular from non-regular on iOS 12 & 13
            if #available(iOS 14.0, *) { } else {
                contentViewController.preferredDisplayMode = .primaryHidden
            }
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        configureBarButtons(searchIsActive: searchController.isActive, animated: false)
    }
    
    // MARK: - Public
    
    func openURL(_ url: URL) {
        if url.isKiwixURL {
            webViewController.webView.load(URLRequest(url: url))
            if #available(iOS 14.0, *) {
                contentViewController.setViewController(webViewController, for: .secondary)
            } else if !(contentViewController.viewControllers.last is WebViewController) {
                contentViewController.viewControllers[contentViewController.viewControllers.count - 1] = webViewController
            }
            if searchController.isActive {
                dismissSearch()
            }
        }
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
    
    func openMainPage(zimFileID: String) {
        guard let url = ZimMultiReader.shared.getMainPageURL(zimFileID: zimFileID) else { return }
        openURL(url)
    }
    
    func openRandomPage(zimFileID: String? = nil) {
        guard let zimFileID = zimFileID ?? onDeviceZimFiles?.map({ $0.id }).randomElement(),
              let url = ZimMultiReader.shared.getRandomPageURL(zimFileID: zimFileID) else { return }
        openURL(url)
    }
    
    // MARK: - Setup & Configurations
    
    private func configureBarButtons(searchIsActive: Bool, animated: Bool) {
        if searchIsActive {
            navigationItem.setLeftBarButton(nil, animated: animated)
            navigationItem.setRightBarButton(cancelButton, animated: animated)
            setToolbarItems(nil, animated: animated)
            navigationController?.setToolbarHidden(true, animated: animated)
        } else if traitCollection.horizontalSizeClass == .regular {
            let left = BarButtonGroup(buttons: buttonProvider.navigationLeftButtons, spacing: 12)
            let right = BarButtonGroup(buttons: navigationRightButtons, spacing: 12)
            navigationItem.setLeftBarButton(UIBarButtonItem(customView: left), animated: animated)
            navigationItem.setRightBarButton(UIBarButtonItem(customView: right), animated: animated)
            setToolbarItems(nil, animated: animated)
            navigationController?.setToolbarHidden(true, animated: animated)
        } else if traitCollection.horizontalSizeClass == .compact {
            navigationItem.setLeftBarButton(nil, animated: animated)
            navigationItem.setRightBarButton(nil, animated: animated)
            setToolbarItems([UIBarButtonItem(customView: BarButtonGroup(buttons: toolbarButtons))], animated: animated)
            navigationController?.setToolbarHidden(false, animated: animated)
        } else {
            navigationItem.setLeftBarButton(nil, animated: animated)
            navigationItem.setRightBarButton(nil, animated: animated)
            setToolbarItems(nil, animated: animated)
            navigationController?.setToolbarHidden(true, animated: animated)
        }
    }
    
    fileprivate func setupContentViewController() {
        contentViewController.presentsWithGesture = false
        contentViewController.viewControllers = [UIViewController(), welcomeController]
        contentViewController.preferredDisplayMode = .primaryHidden
        contentViewController.delegate = self
    }
    
    // MARK: - UISearchControllerDelegate
    
    func willPresentSearchController(_ searchController: UISearchController) {
        configureBarButtons(searchIsActive: true, animated: true)
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        configureBarButtons(searchIsActive: false, animated: true)
    }
    
    // MARK: - UISplitViewControllerDelegate
    
    func primaryViewController(forCollapsing splitViewController: UISplitViewController) -> UIViewController? {
        splitViewController.viewControllers.last
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        splitViewController.viewControllers.last
    }

    // MARK: - WKNavigationDelegate
    
    @available(iOS 13.0, *)
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        guard let url = navigationAction.request.url else { decisionHandler(.cancel, preferences); return }
        if url.isKiwixURL {
            guard let zimFileID = url.host else { decisionHandler(.cancel, preferences); return }
            if let redirectedPath = ZimMultiReader.shared.getRedirectedPath(zimFileID: zimFileID, contentPath: url.path),
                let redirectedURL = URL(zimFileID: zimFileID, contentPath: redirectedPath) {
                decisionHandler(.cancel, preferences)
                openURL(redirectedURL)
            } else {
                preferences.preferredContentMode = .mobile
                decisionHandler(.allow, preferences)
            }
        } else if url.scheme == "http" || url.scheme == "https" {
            let policy = Defaults[.externalLinkLoadingPolicy]
            if policy == .alwaysLoad {
                self.present(SFSafariViewController(url: url), animated: true, completion: nil)
            } else {
                present(UIAlertController.externalLink(policy: policy, action: {
                    self.present(SFSafariViewController(url: url), animated: true, completion: nil)
                }), animated: true)
            }
            decisionHandler(.cancel, preferences)
        } else if url.scheme == "geo" {
            decisionHandler(.cancel, preferences)
        } else {
            decisionHandler(.cancel, preferences)
        }
    }
    
    // for iOS 12
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { decisionHandler(.cancel); return }
        if url.isKiwixURL {
            guard let zimFileID = url.host else { decisionHandler(.cancel); return }
            if let redirectedPath = ZimMultiReader.shared.getRedirectedPath(zimFileID: zimFileID, contentPath: url.path),
                let redirectedURL = URL(zimFileID: zimFileID, contentPath: redirectedPath) {
                decisionHandler(.cancel)
                openURL(redirectedURL)
            } else {
                decisionHandler(.allow)
            }
        } else if url.scheme == "http" || url.scheme == "https" {
            let policy = Defaults[.externalLinkLoadingPolicy]
            if policy == .alwaysLoad {
                self.present(SFSafariViewController(url: url), animated: true, completion: nil)
            } else {
                present(UIAlertController.externalLink(policy: policy, action: {
                    self.present(SFSafariViewController(url: url), animated: true, completion: nil)
                }), animated: true)
            }
            decisionHandler(.cancel)
        } else if url.scheme == "geo" {
            decisionHandler(.cancel)
        } else {
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = Bundle.main.url(forResource: "Inject", withExtension: "js"), let javascript = try? String(contentsOf: url) {
            webView.evaluateJavaScript(javascript) { _, _ in
                if #available(iOS 14.0, *), let outlineViewController = self.contentViewController.viewController(for: .primary) as? OutlineViewController {
                    outlineViewController.reload()
                } else if let outlineViewController = self.contentViewController.viewControllers.first as? OutlineViewController {
                    outlineViewController.reload()
                }
            }
        }
        webViewController.adjustTextSize()
    }
    
    // MARK: - Actions
    
    @objc func goBack() {
        webViewController.webView.goBack()
    }
    
    @objc func goForward() {
        webViewController.webView.goForward()
    }
    
    @objc func toggleOutline() {
        let outlineViewController = OutlineViewController(webView: webViewController.webView)
        if #available(iOS 14.0, *), traitCollection.horizontalSizeClass == .regular {
            if contentViewController.displayMode == .secondaryOnly {
                showSidebar(outlineViewController)
            } else if !(contentViewController.viewController(for: .primary) is OutlineViewController) {
                contentViewController.setViewController(outlineViewController, for: .primary)
            } else {
                hideSidebar()
            }
        } else if traitCollection.horizontalSizeClass == .regular {
            if contentViewController.displayMode == .primaryHidden {
                showSidebar(outlineViewController)
            } else if !(contentViewController.viewControllers.first is OutlineViewController) {
                contentViewController.viewControllers[0] = outlineViewController
            } else {
                hideSidebar()
            }
        } else {
            let navigationController = UINavigationController(rootViewController: outlineViewController)
            present(navigationController, animated: true)
        }
    }
    
    @objc func bookmarkButtonPressed() {
        let bookmarksController = BookmarksViewController()
        bookmarksController.bookmarkTapped = { [weak self] url in self?.openURL(url) }
        if #available(iOS 14.0, *), traitCollection.horizontalSizeClass == .regular {
            if contentViewController.displayMode == .secondaryOnly {
                showSidebar(bookmarksController)
            } else if !(contentViewController.viewController(for: .primary) is BookmarksViewController) {
                contentViewController.setViewController(bookmarksController, for: .primary)
            } else {
                hideSidebar()
            }
        } else if traitCollection.horizontalSizeClass == .regular {
            if contentViewController.displayMode == .primaryHidden {
                showSidebar(bookmarksController)
            } else if !(contentViewController.viewControllers.first is BookmarksViewController) {
                contentViewController.viewControllers[0] = bookmarksController
            } else {
                hideSidebar()
            }
        } else {
            let navigationController = UINavigationController(rootViewController: bookmarksController)
            present(navigationController, animated: true)
        }
    }
    
    @objc func bookmarkButtonLongPressed(sender: Any) {
        func presentBookmarkHUDController(isBookmarked: Bool) {
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
        
        guard let recognizer = sender as? UILongPressGestureRecognizer,
              recognizer.state == .began,
              let url = webViewController.webView.url else { return }
        let bookmarkService = BookmarkService()
        if let bookmark = bookmarkService.get(url: url) {
            bookmarkService.delete(bookmark)
            presentBookmarkHUDController(isBookmarked: false)
        } else {
            bookmarkService.create(url: url)
            presentBookmarkHUDController(isBookmarked: true)
        }
    }
    
    @objc func diceButtonTapped() {
        if let url = webViewController.webView.url, let zimFileID = url.host {
            openRandomPage(zimFileID: zimFileID)
        } else {
            openRandomPage()
        }
    }
    
    @objc func houseButtonTapped() {
        if let url = webViewController.webView.url, let zimFileID = url.host {
            openMainPage(zimFileID: zimFileID)
        } else if let zimFileID = onDeviceZimFiles?.first?.id {
            openMainPage(zimFileID: zimFileID)
        }
    }
    
    @objc func openLibrary() {
        if #available(iOS 14.0, *), FeatureFlags.swiftUIBasedLibraryEnabled {
            let controller = UIHostingController(rootView: LibraryView())
            controller.rootView.dismiss = { controller.dismiss(animated: true) }
            controller.modalPresentationStyle = .pageSheet
            present(controller, animated: true)
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
    
    @objc func dismissSearch() {
        /*
         We have to dismiss the `searchController` first, so that the `isBeingDismissed` property is correct on the
         `searchResultsController`. We rely on `isBeingDismissed` to understand if the search text is cleared because
         of user tapped cancel button or manually cleared the serach field.
         */
        searchController.dismiss(animated: true)
        searchController.isActive = false
    }
    
    // MARK: - Sidebar
    
    fileprivate func showSidebar(_ controller: UIViewController) {
        if contentViewController.viewControllers.count == 1 {
            contentViewController.viewControllers.insert(controller, at: 0)
        } else {
            contentViewController.viewControllers[0] = controller
        }
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
            self.contentViewController.preferredDisplayMode = {
                if #available(iOS 13.0, *) {
                    switch Defaults[.sideBarDisplayMode] {
                    case .automatic:
                        let size = self.view.frame.size
                        return size.width > size.height ? .allVisible : .primaryOverlay
                    case .overlay:
                        return .primaryOverlay
                    case .sideBySide:
                        return .allVisible
                    }
                } else {
                    return .allVisible
                }
            }()
        }
    }
    
    fileprivate func hideSidebar() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn) {
            self.contentViewController.preferredDisplayMode = .primaryHidden
        } completion: { completed in
            guard completed else { return }
            self.contentViewController.viewControllers[0] = UIViewController()
        }
    }
}

@available(iOS 14.0, *)
class RootViewController_iOS14: RootViewController {
    private var onDeviceZimFilesObserver: NotificationToken?
    private var sideBarDisplayModeObserver: Defaults.Observation?
    
    override var toolbarButtons: [BarButton] {
        [buttonProvider.chevronLeftButton, buttonProvider.chevronRightButton, buttonProvider.outlineButton, buttonProvider.bookmarkButton, diceButton, houseButton]
    }
    
    // MARK: - Init & Overrides
    
    init() {
        super.init(contentViewController: UISplitViewController(style: .doubleColumn))
        onDeviceZimFilesObserver = onDeviceZimFiles?.observe { change in
            self.setupDiceButtonMenu()
            self.setupHouseButtonMenu()
        }
        sideBarDisplayModeObserver = Defaults.observe(.sideBarDisplayMode) { change in
            switch(Defaults[.sideBarDisplayMode]) {
            case .automatic:
                self.contentViewController.preferredSplitBehavior = .automatic
                self.contentViewController.preferredDisplayMode = .automatic
            case .overlay:
                self.contentViewController.preferredSplitBehavior = .overlay
                if self.contentViewController.displayMode == .oneBesideSecondary {
                    self.contentViewController.preferredDisplayMode = .oneOverSecondary
                }
            case .sideBySide:
                self.contentViewController.preferredSplitBehavior = .tile
                if self.contentViewController.displayMode == .oneOverSecondary {
                    self.contentViewController.preferredDisplayMode = .oneBesideSecondary
                }
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setupHouseButtonMenu()
    }
    
    // MARK: - Setup & Configurations
    
    fileprivate override func setupContentViewController() {
        contentViewController.presentsWithGesture = false
        let homeViewController = UIHostingController(rootView: HomeView())
        homeViewController.rootView.zimFileTapped = openMainPage
        homeViewController.rootView.libraryButtonTapped = openLibrary
        homeViewController.rootView.settingsButtonTapped = openSettings
        contentViewController.setViewController(homeViewController, for: .secondary)
    }
    
    private func setupDiceButtonMenu() {
        let items = onDeviceZimFiles?.map { zimFile in
            UIAction(title: zimFile.title) { _ in self.openRandomPage(zimFileID: zimFile.id) }
        } ?? [UIAction(title: "No Zim File Available", attributes: .disabled, handler: { _ in })]
        diceButton.menu = UIMenu(children: items)
    }
    
    private func setupHouseButtonMenu() {
        var items = [UIMenuElement]()
        if let zimFiles = onDeviceZimFiles {
            items.append(UIMenu(options: .displayInline, children: zimFiles.map { zimFile in
                UIAction(title: zimFile.title) { _ in self.openMainPage(zimFileID: zimFile.id) }
            }))
        } else {
            items.append(UIAction(title: "No Zim File Available", attributes: .disabled, handler: { _ in }))
        }
        if traitCollection.horizontalSizeClass == .compact {
            items.append(UIMenu(options: .displayInline, children: [
                UIAction(title: "Open Library", image: UIImage(systemName: "books.vertical"), handler: { _ in self.openLibrary() }),
                UIAction(title: "Open Settings", image: UIImage(systemName: "gear"), handler: { _ in self.openSettings() }),
            ]))
        }
        houseButton.menu = UIMenu(children: items)
    }
    
    // MARK: - Sidebar
    
    fileprivate override func showSidebar(_ controller: UIViewController) {
        contentViewController.setViewController(controller, for: .primary)
        contentViewController.show(.primary)
        contentViewController.preferredDisplayMode = {
            switch Defaults[.sideBarDisplayMode] {
            case .automatic:
                return .automatic
            case .overlay:
                return .oneOverSecondary
            case .sideBySide:
                return .oneBesideSecondary
            }
        }()
    }
    
    fileprivate override func hideSidebar() {
        contentViewController.hide(.primary)
        transitionCoordinator?.animate(alongsideTransition: { _ in }, completion: { context in
            guard !context.isCancelled else { return }
            self.contentViewController.setViewController(nil, for: .primary)
        })
    }
}
