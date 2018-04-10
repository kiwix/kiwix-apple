//
//  MainViewController.swift
//  Kiwix
//
//  Created by Chris Li on 11/7/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import CoreData
import NotificationCenter
import SwiftyUserDefaults

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
    
    var shouldShowSearch = false
    var isShowingPanel: Bool {
        return panelContainerLeadingConstraint.priority.rawValue > 750
    }
    
    @IBOutlet weak var panelContainerLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var dividerWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var panelContainer: UIView!
    @IBOutlet weak var tabContainer: UIView!
    
    // MARK: - Controllers
    
    private(set) weak var currentWebController: (UIViewController & WebViewController)? = nil
    private(set) var webControllers = [(UIViewController & WebViewController)]()
    
    let searchController = UISearchController(searchResultsController: SearchResultController())
    private(set) lazy var welcomeController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WelcomeController") as! WelcomeController
    private(set) lazy var bookmarkController = BookmarkController()
    private(set) lazy var tableOfContentController = TableOfContentController()
    private(set) lazy var libraryController = LibraryController()
    private(set) lazy var settingController = SettingNavigationController()
    
    private(set) weak var currentPanelController: UIViewController? = nil
    private(set) weak var currentTabController: UIViewController? = nil
    
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
        navigationBackButtonItem.button.isEnabled = false
        navigationForwardButtonItem.button.isEnabled = false
        setTabContainerChild(controller: welcomeController)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: .UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: .UIApplicationDidBecomeActive, object: nil)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
            DispatchQueue.main.async { self.configureToolbar() }
        }
        
        /*
         When horizontalSizeClass has changed,
         if table of content or bookmark is presented,
         we dismiss the presentation and show the view controller in side panel.
        */
        if traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
            if let presentedNavigationController = navigationController?.presentedViewController as? UINavigationController,
                let topController = presentedNavigationController.topViewController {
                guard topController === tableOfContentController || topController === bookmarkController else {return}
                presentedNavigationController.setViewControllers([], animated: false)
                presentedNavigationController.dismiss(animated: false, completion: {
                    self.setPanelContainerChild(controller: topController)
                    self.showPanel(animated: false)
                })
            }
        }
        
        /*
         When horizontally compact, hide whatever view controller the side panel is showing
         */
        if traitCollection.horizontalSizeClass == .compact {
            hidePanel(animated: false)
            setPanelContainerChild(controller: nil)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        DispatchQueue.main.async { self.configureToolbar() }
    }
    
    override func viewWillLayoutSubviews() {
        dividerWidthConstraint.constant = 1 / UIScreen.main.scale
        super.viewWillLayoutSubviews()
    }
    
    @objc func appWillEnterForeground() {
        DispatchQueue.main.async { self.configureToolbar() }
    }
    
    @objc func appDidBecomeActive() {
        DispatchQueue.main.async {
            guard self.shouldShowSearch && !self.searchController.isActive else {return}
            self.searchController.isActive = true
            self.shouldShowSearch = false
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIApplicationDidBecomeActive, object: nil)
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
            setTabContainerChild(controller: controller)
            webControllers.append(controller)
            currentWebController = controller
            load(url: url)
        }
    }
    
    func webViewDidFinishLoading(controller: WebViewController) {
        navigationBackButtonItem.button.isEnabled = controller.canGoBack
        navigationForwardButtonItem.button.isEnabled = controller.canGoForward
        if let url = currentWebController?.currentURL,
            let article = Article.fetch(url: url, insertIfNotExist: true, context: PersistentContainer.shared.viewContext) {
            article.title = controller.currentTitle
            article.lastReadDate = Date()
            currentArticle = article
        } else {
            bookmarkButtonItem.button.isBookmarked = false
        }
        
        if currentPanelController === tableOfContentController {
            updateTableOfContentsIfNeeded()
        }
        
        if let scale = Defaults[.webViewZoomScale], scale != 1 {
            currentWebController?.adjustFontSize(scale: scale)
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
        guard let searchResultController = searchController.searchResultsController as? SearchResultController,
            let result = searchResultController.searchResultsListController.results.first else {return}
        searchResultController.searchNoTextController.add(recentSearchText: searchResultController.searchText)
        load(url: result.url)
        searchController.isActive = false
    }
    
    func willPresentSearchController(_ searchController: UISearchController) {
        if traitCollection.horizontalSizeClass == .compact {
            navigationController?.setToolbarHidden(true, animated: true)
            if UIDevice.current.userInterfaceIdiom == .pad {
                navigationItem.setRightBarButton(cancelButton, animated: true)
            }
        }
    }
    
    func didPresentSearchController(_ searchController: UISearchController) {
        /* Used to focus on the search bar and show keyboard when searchController is actived using the isActive property */
        DispatchQueue.main.async {
            guard !searchController.searchBar.isFirstResponder else {return}
            self.searchController.searchBar.becomeFirstResponder()
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
    
    func updateBookmarkWidgetData() {
        let context = PersistentContainer.shared.viewContext
        let bookmarks = Article.fetchRecentBookmarks(count: 8, context: context)
            .map({ (article) -> [String: Any]? in
                guard let title = article.title, let url = article.url else {return nil}
                return [
                    "title": title,
                    "url": url.absoluteString,
                    "thumbImageData": article.thumbnailData ?? article.book?.favIcon ?? Data()
                ]
            }).flatMap({ $0 })
        UserDefaults(suiteName: "group.kiwix")?.set(bookmarks, forKey: "bookmarks")
        NCWidgetController().setHasContent(bookmarks.count > 0, forWidgetWithBundleIdentifier: "self.Kiwix.Bookmarks")
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
            tableOfContentController.delegate = self
            updateTableOfContentsIfNeeded(completion: {
                self.presentAdaptively(controller: self.tableOfContentController, animated: true)
            })
        case bookmarkButtonItem:
            bookmarkController.delegate = self
            presentAdaptively(controller: bookmarkController, animated: true)
        case libraryButtonItem:
            present(libraryController, animated: true, completion: nil)
        case settingButtonItem:
            present(settingController, animated: true, completion: nil)
        default:
            break
        }
    }
    
    func buttonLongPressed(item: BarButtonItem, button: UIButton) {
        switch item {
        case bookmarkButtonItem:
            let context = PersistentContainer.shared.viewContext
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
                self.updateBookmarkWidgetData()
            })
        default:
            break
        }
    }
}

// MARK: - View Manipulation

extension MainController {
    private func showPanel(animated: Bool) {
        view.layoutIfNeeded()
        panelContainerLeadingConstraint.priority = UILayoutPriority(751)
        
        if animated {
            UIView.animateKeyframes(withDuration: 0.2, delay: 0.0, options: .calculationModeCubic, animations: {
                self.view.layoutIfNeeded()
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.25, animations: {
                    if self.currentTabController is WebViewController {
                        self.tabContainer.alpha = 0.5
                    }
                })
                UIView.addKeyframe(withRelativeStartTime: 0.25, relativeDuration: 0.75, animations: {
                    if self.currentTabController is WebViewController {
                        self.tabContainer.alpha = 1.0
                    }
                })
            })
        } else {
            view.layoutIfNeeded()
        }
    }
    
    private func hidePanel(animated: Bool, completion: ((Bool) -> Void)? = nil) {
        view.layoutIfNeeded()
        panelContainerLeadingConstraint.priority = UILayoutPriority(749)
        
        if animated {
            UIView.animateKeyframes(withDuration: 0.2, delay: 0.0, options: .calculationModeCubic, animations: {
                self.view.layoutIfNeeded()
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.25, animations: {
                    if self.currentTabController is WebViewController {
                        self.tabContainer.alpha = 0.5
                    }
                })
                UIView.addKeyframe(withRelativeStartTime: 0.25, relativeDuration: 0.75, animations: {
                    if self.currentTabController is WebViewController {
                        self.tabContainer.alpha = 1.0
                    }
                })
            }, completion: completion)
        } else {
            view.layoutIfNeeded()
            completion?(true)
        }
    }
    
    private func setPanelContainerChild(controller: UIViewController?) {
        defer {currentPanelController = controller}
        guard currentPanelController !== controller else {return}
        currentPanelController?.view.removeFromSuperview()
        currentPanelController?.removeFromParentViewController()
        
        guard let controller = controller else {return}
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        panelContainer.addSubview(controller.view)
        addChildViewController(controller)
        NSLayoutConstraint.activate([
            controller.view.leftAnchor.constraint(equalTo: panelContainer.leftAnchor),
            controller.view.rightAnchor.constraint(equalTo: panelContainer.rightAnchor),
            controller.view.topAnchor.constraint(equalTo: panelContainer.topAnchor),
            controller.view.bottomAnchor.constraint(equalTo: panelContainer.bottomAnchor)])
        controller.didMove(toParentViewController: self)
    }
    
    private func setTabContainerChild(controller: UIViewController?) {
        defer {currentTabController = controller}
        guard currentTabController !== controller else {return}
        currentTabController?.view.removeFromSuperview()
        currentTabController?.removeFromParentViewController()
        
        guard let controller = controller else {return}
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        tabContainer.addSubview(controller.view)
        addChildViewController(controller)
        if controller is WelcomeController {
            NSLayoutConstraint.activate([
                controller.view.leftAnchor.constraint(equalTo: tabContainer.leftAnchor),
                controller.view.rightAnchor.constraint(equalTo: tabContainer.rightAnchor),
                controller.view.topAnchor.constraint(equalTo: tabContainer.topAnchor),
                controller.view.bottomAnchor.constraint(equalTo: tabContainer.bottomAnchor)])
        } else {
            if #available(iOS 11.0, *) {
                NSLayoutConstraint.activate([
                    controller.view.leftAnchor.constraint(equalTo: tabContainer.leftAnchor),
                    controller.view.rightAnchor.constraint(equalTo: tabContainer.rightAnchor),
                    controller.view.topAnchor.constraint(equalTo: tabContainer.safeAreaLayoutGuide.topAnchor),
                    controller.view.bottomAnchor.constraint(equalTo: tabContainer.safeAreaLayoutGuide.bottomAnchor)])
            } else {
                automaticallyAdjustsScrollViewInsets = false
                NSLayoutConstraint.activate([
                    controller.view.leftAnchor.constraint(equalTo: tabContainer.leftAnchor),
                    controller.view.rightAnchor.constraint(equalTo: tabContainer.rightAnchor),
                    controller.view.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
                    controller.view.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor)])
            }
        }
        
        controller.didMove(toParentViewController: self)
    }
    
    func presentAdaptively(controller: UIViewController, animated: Bool) {
        if traitCollection.horizontalSizeClass == .compact {
            presentModally(controller: controller, animated: animated)
        } else {
            if isShowingPanel {
                if currentPanelController === controller {
                    hidePanel(animated: animated, completion: { _ in
                        self.setPanelContainerChild(controller: nil)
                    })
                } else {
                    setPanelContainerChild(controller: controller)
                }
            } else {
                setPanelContainerChild(controller: controller)
                showPanel(animated: animated)
            }
        }
    }
    
    private func presentModally(controller: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
        controller.view.translatesAutoresizingMaskIntoConstraints = true
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.view.backgroundColor = .white
        navigationController.modalPresentationStyle = .overFullScreen
        if #available(iOS 11.0, *) {
            navigationController.navigationBar.prefersLargeTitles = true
        }
        self.navigationController?.present(navigationController, animated: animated, completion: completion)
    }
}
