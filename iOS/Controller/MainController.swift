//
//  MainViewController.swift
//  Kiwix
//
//  Created by Chris Li on 11/7/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import CoreData

class MainController: UIViewController {
    private var currentArticleBookmarkObserver: NSKeyValueObservation? = nil
    private var currentArticle: Article? = nil {
        didSet {
            guard let article = currentArticle else {return}
            
            // update bookmark button when the bookmark state of current article is changed
            bookmarkButtonItem.button.isBookmarked = article.isBookmarked
            currentArticleBookmarkObserver = article.observe(\.isBookmarked) { (article, change) in
                self.bookmarkButtonItem.button.isBookmarked = article.isBookmarked
            }
        }
    }

    // MARK: - Controllers
    
    let searchController = UISearchController(searchResultsController: SearchResultController())
    private weak var currentWebController: (UIViewController & WebViewController)? = nil
    private(set) var webControllers = [(UIViewController & WebViewController)]()
    private(set) lazy var welcomeController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WelcomeController") as! WelcomeController
    private(set) lazy var bookmarkController = BookmarkController()
    private(set) lazy var tableOfContentController = TableOfContentController()
    private(set) lazy var libraryController = LibraryController()
    private(set) lazy var settingController = SettingNavigationController()
    
    // MARK: - Toolbar
    
    private lazy var navigationBackButtonItem = BarButtonItem(image: #imageLiteral(resourceName: "Left"), inset: 12, delegate: self)
    private lazy var navigationForwardButtonItem = BarButtonItem(image: #imageLiteral(resourceName: "Right"), inset: 12, delegate: self)
    private lazy var tableOfContentButtonItem = BarButtonItem(image: #imageLiteral(resourceName: "TableOfContent"), inset: 8, delegate: self)
    private lazy var bookmarkButtonItem = BookmarkButtonItem(delegate: self)
    private lazy var libraryButtonItem = BarButtonItem(image: #imageLiteral(resourceName: "Library"), inset: 6, delegate: self)
    private lazy var settingButtonItem = BarButtonItem(image: #imageLiteral(resourceName: "Setting"), inset: 8, delegate: self)
    private lazy var cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelSearchButtonTapped))
    
    // MARK: - Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSearchController()
        definesPresentationContext = true
        navigationItem.titleView = searchController.searchBar
        setChildController(controller: welcomeController)
        navigationBackButtonItem.button.isEnabled = false
        navigationForwardButtonItem.button.isEnabled = false
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: .UIApplicationWillEnterForeground, object: nil)
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
    
    @objc func appWillEnterForeground() {
        DispatchQueue.main.async { self.configureToolbar() }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .UIApplicationWillEnterForeground, object: nil)
    }
    
    private func setChildController(controller: UIViewController) {
        view.subviews.forEach({ $0.removeFromSuperview() })
        childViewControllers.forEach({ $0.removeFromParentViewController() })
        
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(controller)
        view.addSubview(controller.view)
        if let controller = controller as? WelcomeController {
            NSLayoutConstraint.activate([
                controller.view.topAnchor.constraint(equalTo: view.topAnchor),
                controller.view.leftAnchor.constraint(equalTo: view.leftAnchor),
                controller.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                controller.view.rightAnchor.constraint(equalTo: view.rightAnchor)])
        } else {
            NSLayoutConstraint.activate([
                controller.view.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
                controller.view.leftAnchor.constraint(equalTo: view.leftAnchor),
                controller.view.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor),
                controller.view.rightAnchor.constraint(equalTo: view.rightAnchor)])
        }
        controller.didMove(toParentViewController: self)
    }
}

// MARK: - Tab Management

extension MainController: WebViewControllerDelegate {
    func load(url: URL) {
        if let controller = currentWebController {
            controller.load(url: url)
        } else {
            var controller: (UIViewController & WebViewController) = {
                if #available(iOS 11.0, *) {
                    return WebKitWebController()
                } else {
                    return LegacyWebController()
                }
            }()
            controller.delegate = self
            setChildController(controller: controller)
            webControllers.append(controller)
            currentWebController = controller
            load(url: url)
        }
    }
    
    func webViewDidFinishLoading(controller: WebViewController) {
        navigationBackButtonItem.button.isEnabled = controller.canGoBack
        navigationForwardButtonItem.button.isEnabled = controller.canGoForward
        if let url = currentWebController?.currentURL,
            let article = Article.fetch(url: url, insertIfNotExist: true, context: CoreDataContainer.shared.viewContext) {
            article.title = controller.currentTitle
            article.lastReadDate = Date()
            currentArticle = article
        } else {
            bookmarkButtonItem.button.isBookmarked = false
        }
    }
}

// MARK: - Search

extension MainController: UISearchControllerDelegate, UISearchBarDelegate {
    private func configureSearchController() {
        searchController.delegate = self
        searchController.searchBar.delegate = self
        searchController.searchBar.returnKeyType = .go
        searchController.searchBar.autocorrectionType = .no
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.searchBarStyle = .minimal
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.obscuresBackgroundDuringPresentation = true
        searchController.searchResultsUpdater = searchController.searchResultsController as? SearchResultController
    }
    
    @objc func cancelSearchButtonTapped() {
        searchController.isActive = false
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        // when searchController become active, set searchBar.text to previous search text
        searchBar.text = (searchController.searchResultsController as? SearchResultController)?.searchText
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
//        guard let searchRe
    }
    
    func willPresentSearchController(_ searchController: UISearchController) {
        if traitCollection.horizontalSizeClass == .compact {
            navigationController?.setToolbarHidden(true, animated: true)
            if UIDevice.current.userInterfaceIdiom == .pad {
                navigationItem.setRightBarButton(cancelButton, animated: true)
            }
        }
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        if traitCollection.horizontalSizeClass == .compact {
            navigationController?.setToolbarHidden(false, animated: true)
            if UIDevice.current.userInterfaceIdiom == .pad {
                navigationItem.setRightBarButton(nil, animated: true)
            }
        }
    }
}

// MARK: - Functions

extension MainController: TableOfContentControllerDelegate, BookmarkControllerDelegate {
    private func updateTableOfContentsIfNeeded(completion: (() -> Void)? = nil) {
        guard let webController = currentWebController, tableOfContentController.url != webController.currentURL else {completion?(); return}
        webController.extractTableOfContents(completion: { (currentURL, items) in
            self.tableOfContentController.url = currentURL
            self.tableOfContentController.items = items
            completion?()
        })
    }
    
    func didTapTableOfContentItem(index: Int, item: TableOfContentItem) {
        currentWebController?.scrollToTableOfContentItem(index: index)
    }
    
    func didTapBookmark(articleURL: URL) {
        load(url: articleURL)
    }
}

// MARK: - Bar Buttons

extension MainController: BarButtonItemDelegate {
    private func configureToolbar() {
        toolbarItems = nil
        navigationItem.leftBarButtonItems = nil
        navigationItem.rightBarButtonItems = nil
        switch traitCollection.horizontalSizeClass {
        case .regular:
            navigationController?.isToolbarHidden = true
            navigationItem.leftBarButtonItems = [navigationBackButtonItem, navigationForwardButtonItem, tableOfContentButtonItem]
            navigationItem.rightBarButtonItems = [settingButtonItem, libraryButtonItem, bookmarkButtonItem]
            
            /*
             this following code snippet is for fixing position of popover when horizonal regular
             we re-added all buttons and that is making popover forgetting about its position
             */
            if let presented = presentedViewController as? TableOfContentController {
                presented.dismiss(animated: false, completion: {
                    self.presentTableOfContentController(animated: false)
                })
            } else if let presented = presentedViewController as? BookmarkController {
                presented.dismiss(animated: false, completion: {
                    self.presentBookmarkController(animated: false)
                })
            }
        case .compact:
            navigationController?.isToolbarHidden = searchController.isActive ? true : false
            toolbarItems = [navigationBackButtonItem, navigationForwardButtonItem, tableOfContentButtonItem, bookmarkButtonItem, libraryButtonItem, settingButtonItem].enumerated()
                .reduce([], { $0 + ($1.offset > 0 ? [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), $1.element] : [$1.element]) })
            
            // the search bar won't show cancel button on iPad when horizonal compact, we have to make one and add it ourselves
            if searchController.isActive && UIDevice.current.userInterfaceIdiom == .pad {
                navigationItem.setRightBarButton(cancelButton, animated: false)
            }
        default:
            break
        }
    }
    
    func buttonTapped(item: BarButtonItem, button: UIButton) {
        switch item {
        case navigationBackButtonItem:
            currentWebController?.goBack()
        case navigationForwardButtonItem:
            currentWebController?.goForward()
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
            guard let webController = currentWebController,
                let article = currentArticle else {return}
            
            article.isBookmarked = !article.isBookmarked
            article.bookmarkDate = Date()

            if article.isBookmarked {
                webController.extractSnippet(completion: { (snippet) in
                    context.perform({
                        article.snippet = snippet
                    })
                })

                if article.book?.hasPic ?? false {
                    webController.extractImageURLs(completion: { (urls) in
                        guard let url = urls.first else {return}
                        context.perform({
                            article.thumbImagePath = url.path
                        })
                    })
                }
            }

            let controller = HUDController()
            controller.modalPresentationStyle = .custom
            controller.transitioningDelegate = controller
            controller.direction = article.isBookmarked ? .down : .up
            controller.imageView.image = article.isBookmarked ? #imageLiteral(resourceName: "StarAdd") : #imageLiteral(resourceName: "StarRemove")
            controller.label.text = article.isBookmarked ?
                NSLocalizedString("Added", comment: "Bookmark HUD") :
                NSLocalizedString("Removed", comment: "Bookmark HUD")

            present(controller, animated: true, completion: {
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
        updateTableOfContentsIfNeeded(completion: {
            self.tableOfContentController.delegate = self
            self.tableOfContentController.modalPresentationStyle = .popover
            self.tableOfContentController.popoverPresentationController?.sourceView = self.tableOfContentButtonItem.button
            self.tableOfContentController.popoverPresentationController?.sourceRect = self.tableOfContentButtonItem.button.bounds
            self.tableOfContentController.popoverPresentationController?.delegate = self
            self.tableOfContentController.preferredContentSize = CGSize(width: 300, height: 400)
            self.present(self.tableOfContentController, animated: true)
        })
    }
    
    private func presentBookmarkController(animated: Bool) {
        bookmarkController.delegate = self
        bookmarkController.modalPresentationStyle = .popover
        bookmarkController.popoverPresentationController?.sourceView = bookmarkButtonItem.button
        bookmarkController.popoverPresentationController?.sourceRect = bookmarkButtonItem.button.bounds
        bookmarkController.popoverPresentationController?.delegate = self
        bookmarkController.preferredContentSize = CGSize(width: 400, height: 600)
        present(bookmarkController, animated: true)
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
