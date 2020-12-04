//
//  RootViewController.swift
//  Kiwix
//
//  Created by Chris Li on 11/28/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import UIKit
import WebKit
import SafariServices
import Defaults

class RootViewController: UIViewController, UISearchControllerDelegate, WKNavigationDelegate {
    let searchController: UISearchController
    private let searchResultsController: SearchResultsController
    private let contentViewController: UISplitViewController
    private let welcomeController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WelcomeController") as! WelcomeController
    private let webViewController = WebViewController()
    
    // MARK: Buttons
    
    private let chevronLeftButton = BarButton(imageName: "chevron.left")
    private let chevronRightButton = BarButton(imageName: "chevron.right")
    private let outlineButton = BarButton(imageName: "list.bullet")
    private let bookmarkButton = BookmarkButton(imageName: "star", bookmarkedImageName: "star.fill")
    private let diceButton = BarButton(imageName: "die.face.5")
    private let houseButton = BarButton(imageName: "house")
    private let libraryButton = BarButton(imageName: "folder")
    private let settingButton = BarButton(imageName: "gear")
    private let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
    private let bookmarkLongPressGestureRecognizer = UILongPressGestureRecognizer()
    
    // MARK: - Init & Overrides
    
    init() {
        self.searchResultsController = SearchResultsController()
        self.searchController = UISearchController(searchResultsController: self.searchResultsController)
        if #available(iOS 14.0, *) {
            self.contentViewController = UISplitViewController(style: .doubleColumn)
        } else {
            self.contentViewController = UISplitViewController()
        }
        
        super.init(nibName: nil, bundle: nil)
        
        contentViewController.presentsWithGesture = false
        webViewController.webView.navigationDelegate = self
        
        // wire up button actions
        chevronLeftButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        chevronRightButton.addTarget(self, action: #selector(goForward), for: .touchUpInside)
        outlineButton.addTarget(self, action: #selector(toggleOutline), for: .touchUpInside)
        bookmarkButton.addTarget(self, action: #selector(toggleBookmarks), for: .touchUpInside)
        bookmarkButton.addGestureRecognizer(bookmarkLongPressGestureRecognizer)
        bookmarkLongPressGestureRecognizer.addTarget(self, action: #selector(bookmarkButtonLongPressed))
        cancelButton.target = self
        cancelButton.action = #selector(dismissSearch)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // configure bar buttons
        chevronLeftButton.isEnabled = false
        chevronRightButton.isEnabled = false
        configureBarButtons(searchIsActive: searchController.isActive, animated: false)
        
        // configure content view controller
        if #available(iOS 14.0, *) {
            let navigationController = UINavigationController(rootViewController: welcomeController)
            navigationController.isNavigationBarHidden = true
            contentViewController.setViewController(navigationController, for: .secondary)
        } else {
            contentViewController.preferredDisplayMode = .primaryHidden
            contentViewController.viewControllers = [UIViewController(), welcomeController]
        }
        
        // add content view controller as a child
        addChild(contentViewController)
        contentViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentViewController.view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: contentViewController.view.topAnchor),
            view.leftAnchor.constraint(equalTo: contentViewController.view.leftAnchor),
            view.bottomAnchor.constraint(equalTo: contentViewController.view.bottomAnchor),
            view.rightAnchor.constraint(equalTo: contentViewController.view.rightAnchor),
        ])
        contentViewController.didMove(toParent: self)
        
        // search controller
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
        navigationItem.titleView = searchController.searchBar
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        if newCollection.horizontalSizeClass == .regular {
            presentedViewController?.dismiss(animated: false)
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
            if #available(iOS 14.0, *),
               let navigationController = contentViewController.viewController(for: .secondary) as? UINavigationController,
               !(navigationController.topViewController is OutlineController)  {
                navigationController.setViewControllers([webViewController], animated: false)
            } else if !(contentViewController.viewControllers.last is WebKitWebViewController) {
                contentViewController.viewControllers[1] = webViewController
            }
            if searchController.isActive {
                dismissSearch()
            }
        } else if url.isFileURL {
            
        }
    }
    
    private func getSidebarVisibleDisplayMode(size: CGSize? = nil) -> UISplitViewController.DisplayMode {
        if #available(iOS 14.0, *) {
            switch Defaults[.sideBarDisplayMode] {
            case .automatic:
                let size = size ?? view.frame.size
                return size.width > size.height ? .oneBesideSecondary : .oneOverSecondary
            case .overlay:
                return .oneOverSecondary
            case .sideBySide:
                return .oneBesideSecondary
            }
        } else {
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
    }
    
    // MARK: - Configurations
    
    private func configureBarButtons(searchIsActive: Bool, animated: Bool) {
        if searchIsActive {
            navigationItem.setLeftBarButton(nil, animated: animated)
            navigationItem.setRightBarButton(cancelButton, animated: animated)
            setToolbarItems(nil, animated: animated)
            navigationController?.setToolbarHidden(true, animated: animated)
        } else if traitCollection.horizontalSizeClass == .regular {
            let left = BarButtonGroup(buttons: [chevronLeftButton, chevronRightButton, outlineButton, bookmarkButton], spacing: 10)
            let right = BarButtonGroup(buttons: [diceButton, houseButton, libraryButton, settingButton], spacing: 10)
            navigationItem.setLeftBarButton(UIBarButtonItem(customView: left), animated: animated)
            navigationItem.setRightBarButton(UIBarButtonItem(customView: right), animated: animated)
            setToolbarItems(nil, animated: animated)
            navigationController?.setToolbarHidden(true, animated: animated)
        } else if traitCollection.horizontalSizeClass == .compact {
            let group = BarButtonGroup(buttons: [
                chevronLeftButton, chevronRightButton, outlineButton, bookmarkButton, libraryButton, settingButton,
            ])
            navigationItem.setLeftBarButton(nil, animated: animated)
            navigationItem.setRightBarButton(nil, animated: animated)
            setToolbarItems([UIBarButtonItem(customView: group)], animated: animated)
            navigationController?.setToolbarHidden(false, animated: animated)
        } else {
            navigationItem.setLeftBarButton(nil, animated: animated)
            navigationItem.setRightBarButton(nil, animated: animated)
            setToolbarItems(nil, animated: animated)
            navigationController?.setToolbarHidden(true, animated: animated)
        }
    }
    
    // MARK: - UISearchControllerDelegate
    
    func willPresentSearchController(_ searchController: UISearchController) {
        configureBarButtons(searchIsActive: true, animated: true)
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        configureBarButtons(searchIsActive: false, animated: true)
    }
    
    // MARK: - WKNavigationDelegate
    
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
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        chevronLeftButton.isEnabled = webView.canGoBack
        chevronRightButton.isEnabled = webView.canGoForward
        guard let url = Bundle.main.url(forResource: "Inject", withExtension: "js"),
              let javascript = try? String(contentsOf: url) else { return }
        webView.evaluateJavaScript(javascript) { _, _ in
            if #available(iOS 14.0, *), let outlineViewController = self.contentViewController.viewController(for: .primary) as? OutlineViewController {
                outlineViewController.reload()
            } else if let outlineViewController = self.contentViewController.viewControllers.first as? OutlineViewController {
                outlineViewController.reload()
            }
        }
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
            } else if !(contentViewController.viewControllers.first is OutlineController) {
                contentViewController.viewControllers[0] = outlineViewController
            } else {
                hideSidebar()
            }
        } else {
            let navigationController = UINavigationController(rootViewController: outlineViewController)
            present(navigationController, animated: true)
        }
    }
    
    @objc func toggleBookmarks() {
        let bookmarksController = BookmarksViewController()
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
            bookmarkButton.isBookmarked = false
            presentBookmarkHUDController(isBookmarked: false)
        } else {
            bookmarkService.create(url: url)
            bookmarkButton.isBookmarked = true
            presentBookmarkHUDController(isBookmarked: true)
        }
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
    
    private func showSidebar(_ controller: UIViewController) {
        if #available(iOS 14.0, *) {
            contentViewController.setViewController(controller, for: .primary)
            contentViewController.preferredDisplayMode = getSidebarVisibleDisplayMode()
            contentViewController.show(.primary)
        } else {
            contentViewController.viewControllers[0] = controller
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
                self.contentViewController.preferredDisplayMode = self.getSidebarVisibleDisplayMode()
            }
        }
    }
    
    private func hideSidebar() {
        if #available(iOS 14.0, *) {
            contentViewController.hide(.primary)
            transitionCoordinator?.animate(alongsideTransition: { _ in }, completion: { context in
                guard !context.isCancelled else { return }
                self.contentViewController.setViewController(nil, for: .primary)
            })
        } else {
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn) {
                self.contentViewController.preferredDisplayMode = .primaryHidden
            } completion: { completed in
                guard completed else { return }
                self.contentViewController.viewControllers[0] = UIViewController()
            }
        }
    }
}
