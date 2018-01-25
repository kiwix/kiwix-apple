//
//  MainViewController.swift
//  Kiwix
//
//  Created by Chris Li on 11/7/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class MainController: UIViewController, UISearchControllerDelegate {
    private lazy var cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelSearchButtonTapped))
    private var webControllerObserver: NSKeyValueObservation? = nil

    // MARK: - Controllers
    
    let searchController = UISearchController(searchResultsController: SearchController())
    private(set) var tabContainerController: TabContainerController!
    private(set) lazy var bookmarkController = BookmarkViewController()
    private(set) lazy var tableOfContentController = TableOfContentViewController()
    private(set) lazy var libraryController = LibraryController()
    private(set) lazy var settingController = SettingNavigationController()
    
    // MARK: - Toolbar
    
    private lazy var navigationBackButtonItem = BarButtonItem(image: #imageLiteral(resourceName: "Left"), inset: 12, delegate: self)
    private lazy var navigationForwardButtonItem = BarButtonItem(image: #imageLiteral(resourceName: "Right"), inset: 12, delegate: self)
    private lazy var tableOfContentButtonItem = BarButtonItem(image: #imageLiteral(resourceName: "TableOfContent"), inset: 8, delegate: self)
    private lazy var bookmarkButtonItem = BookmarkButtonItem(delegate: self)
    private lazy var libraryButtonItem = BarButtonItem(image: #imageLiteral(resourceName: "Library"), inset: 6, delegate: self)
    private lazy var settingButtonItem = BarButtonItem(image: #imageLiteral(resourceName: "Setting"), inset: 8, delegate: self)
    
    // MARK: - Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSearchController()
        definesPresentationContext = true
        navigationItem.titleView = searchController.searchBar
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: .UIApplicationWillEnterForeground, object: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        guard let identifier = segue.identifier else {return}
        switch identifier {
        case "TabContainerController":
            tabContainerController = segue.destination as! TabContainerController
            tabContainerController.delegate = self
        default:
            break
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass else {return}
        DispatchQueue.main.async { self.configureToolbar() }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        DispatchQueue.main.async { self.configureToolbar() }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .UIApplicationWillEnterForeground, object: nil)
    }
    
    // MARK: -
    
    private func configureSearchController() {
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.autocorrectionType = .no
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.obscuresBackgroundDuringPresentation = true
        searchController.delegate = self
        searchController.searchResultsUpdater = searchController.searchResultsController as? SearchController
    }
    
    func updateTableOfContents(completion: (() -> Void)? = nil) {
        guard tableOfContentController.url != tabContainerController.webController?.currentURL,
            let webController = tabContainerController.webController else {completion?(); return}
        webController.extractTableOfContents(completion: { (currentURL, items) in
            self.tableOfContentController.url = currentURL
            self.tableOfContentController.items = items
            completion?()
        })
    }
    
    @objc func cancelSearchButtonTapped() {
        searchController.isActive = false
    }
    
    @objc func appWillEnterForeground() {
        DispatchQueue.main.async { self.configureToolbar() }
    }
    
    // MARK: - UISearchControllerDelegate
    
    func willPresentSearchController(_ searchController: UISearchController) {
        if UIDevice.current.userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .compact {
            navigationItem.setRightBarButton(cancelButton, animated: true)
        }
        if traitCollection.horizontalSizeClass == .compact {
            navigationController?.setToolbarHidden(true, animated: true)
        }
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        if UIDevice.current.userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .compact {
            navigationItem.setRightBarButton(nil, animated: true)
        }
        if traitCollection.horizontalSizeClass == .compact {
            navigationController?.setToolbarHidden(false, animated: true)
        }
    }
}

// MARK: - Panel Control

extension MainController: TableOfContentControllerDelegate, BookmarkControllerDelegate {
    func didTapTableOfContentItem(index: Int, item: TableOfContentItem) {
        tabContainerController.webController?.scrollToTableOfContentItem(index: index)
    }
    
    func didTapBookmark(articleURL: URL) {
        tabContainerController.load(url: articleURL)
    }
}

// MARK: - Tab Control

extension MainController: TabContainerControllerDelegate {
    func tabDidFinishLoading(controller: WebViewController) {
        navigationBackButtonItem.button.isGrayed = !controller.canGoBack
        navigationForwardButtonItem.button.isGrayed = !controller.canGoForward
        if let url = tabContainerController.webController?.currentURL,
            let article = Article.fetch(url: url, insertIfNotExist: false, context: CoreDataContainer.shared.viewContext) {
            bookmarkButtonItem.button.isBookmarked = article.isBookmarked
        } else {
            bookmarkButtonItem.button.isBookmarked = false
        }
    }
}

// MARK: - Bar Buttons

extension MainController: BarButtonItemDelegate {
    private func configureToolbar() {
        toolbarItems = nil
        navigationItem.leftBarButtonItems = nil
        navigationItem.rightBarButtonItems = nil
        if traitCollection.horizontalSizeClass == .regular {
            navigationController?.isToolbarHidden = true
            navigationItem.leftBarButtonItems = [navigationBackButtonItem, navigationForwardButtonItem, tableOfContentButtonItem]
            navigationItem.rightBarButtonItems = [settingButtonItem, libraryButtonItem, bookmarkButtonItem]
            
            if let presentedViewController = presentedViewController {
                presentedViewController.dismiss(animated: false, completion: {
                    if presentedViewController === self.tableOfContentController {
                        self.presentTableOfContentController(animated: false)
                    } else if presentedViewController === self.bookmarkController {
                        self.presentBookmarkController(animated: false)
                    }
                })
            }
        } else if traitCollection.horizontalSizeClass == .compact {
            navigationController?.isToolbarHidden = searchController.isActive ? true : false
            toolbarItems = [navigationBackButtonItem, navigationForwardButtonItem, tableOfContentButtonItem, bookmarkButtonItem, libraryButtonItem, settingButtonItem].enumerated()
                .reduce([], { $0 + ($1.offset > 0 ? [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), $1.element] : [$1.element]) })
            if searchController.isActive && UIDevice.current.userInterfaceIdiom == .pad {
                navigationItem.setRightBarButton(cancelButton, animated: false)
            }
        }
    }
    
    func buttonTapped(item: BarButtonItem, button: UIButton) {
        switch item {
        case navigationBackButtonItem:
            tabContainerController.webController?.goBack()
        case navigationForwardButtonItem:
            tabContainerController.webController?.goForward()
        case tableOfContentButtonItem:
            presentTableOfContentController(animated: true)
        case bookmarkButtonItem:
            presentBookmarkController(animated: true)
        case libraryButtonItem:
            present(libraryController, animated: true, completion: nil)
        case settingButtonItem:
            present(settingController, animated: true, completion: nil)
        default:
            break
        }
    }
    
    func buttonLongPresse(item: BarButtonItem, button: UIButton) {
        switch item {
        case bookmarkButtonItem:
            let context = CoreDataContainer.shared.viewContext
            guard let item = item as? BookmarkButtonItem,
                let webController = tabContainerController.webController,
                let url = webController.currentURL,
                let title = webController.currentTitle,
                let article = Article.fetch(url: url, insertIfNotExist: true, context: context) else {return}
            
            article.title = title
            article.isBookmarked = !article.isBookmarked
            article.bookmarkDate = Date()
            webController.extractSnippet(completion: { (snippet) in
                context.perform({
                    article.snippet = snippet
                })
            })
            
            webController.extractImageURLs(completion: { (urls) in
                guard let url = urls.first else {return}
                context.perform({
                    article.thumbImagePath = url.path
                })
            })
            
            let isBookmarked = article.isBookmarked
            let controller = HUDController()
            controller.direction = isBookmarked ? .down : .up
            controller.imageView.image = isBookmarked ? #imageLiteral(resourceName: "StarAdd") : #imageLiteral(resourceName: "StarRemove")
            controller.label.text = isBookmarked ? NSLocalizedString("Added", comment: "Bookmark HUD") : NSLocalizedString("Removed", comment: "Bookmark HUD")
            controller.modalPresentationStyle = .overFullScreen
            controller.transitioningDelegate = controller
            present(controller, animated: true, completion: {
                item.button.isBookmarked = isBookmarked
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    controller.dismiss(animated: true, completion: nil)
                })
            })
        default:
            break
        }
    }
}

// MARK: - Presentation

extension MainController: UIPopoverPresentationControllerDelegate {
    private func presentTableOfContentController(animated: Bool) {
        updateTableOfContents(completion: {
            self.tableOfContentController.delegate = self
            self.tableOfContentController.modalPresentationStyle = .popover
            self.tableOfContentController.popoverPresentationController?.barButtonItem = self.tableOfContentButtonItem
            self.tableOfContentController.popoverPresentationController?.delegate = self
            self.present(self.tableOfContentController, animated: animated)
        })
    }
    
    private func presentBookmarkController(animated: Bool) {
        bookmarkController.modalPresentationStyle = .popover
        bookmarkController.popoverPresentationController?.barButtonItem = bookmarkButtonItem
        bookmarkController.popoverPresentationController?.delegate = self
        present(bookmarkController, animated: animated)
    }
    
    func presentationController(_ controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        if style == .popover {
            return controller.presentedViewController
        } else {
            let navigationController = UINavigationController(rootViewController: controller.presentedViewController)
            navigationController.view.backgroundColor = .white
            if #available(iOS 11.0, *) {
                navigationController.navigationBar.prefersLargeTitles = true
            }
            return navigationController
        }
    }
}
