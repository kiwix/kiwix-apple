//
//  MainViewController.swift
//  Kiwix
//
//  Created by Chris Li on 11/7/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import MapKit
import NotificationCenter
import RealmSwift
import SwiftyUserDefaults

class MainController: UIViewController {
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
    
    func webViewDidTapOnGeoLocation(url: URL) {
        guard let components = URLComponents(string: url.absoluteString) else {return}
        let parts = components.path.split(separator: ",")
        guard parts.count == 2, let latitude = CLLocationDegrees(parts[0]), let longitude = CLLocationDegrees(parts[1]) else {return}
        let location = CLLocation(latitude: latitude, longitude: longitude)
        print(location)
    }
    
    func webViewDidFinishLoading(controller: WebViewController) {
        navigationBackButtonItem.button.isEnabled = controller.canGoBack
        navigationForwardButtonItem.button.isEnabled = controller.canGoForward

        if let url = currentWebController?.currentURL, let zimFileID = url.host {
            do {
                let database = try Realm(configuration: Realm.defaultConfig)
                let predicate = NSPredicate(format: "zimFile.id == %@ AND path == %@", zimFileID, url.path)
                let resultCount = database.objects(Bookmark.self).filter(predicate).count
                bookmarkButtonItem.button.isBookmarked = resultCount > 0
            } catch {}
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
        guard let searchResultController = searchController.searchResultsController as? SearchResultController else {return}
        searchBar.text = searchResultController.contentController.resultsListController.searchText
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // when return button on the keyboard is tapped, we load the first article in search result
        guard let controller = searchController.searchResultsController as? SearchResultController else {return}
        let resultsListController = controller.contentController.resultsListController
        guard let firstResult = resultsListController.results.first else {return}
        
        load(url: firstResult.url)
        resultsListController.update(recentSearchText: resultsListController.searchText)
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
    
    func didDeleteBookmark(url: URL) {
        guard currentWebController?.currentURL?.absoluteString == url.absoluteString else {return}
        bookmarkButtonItem.button.isBookmarked = false
    }
    
    func updateBookmarkWidgetData() {
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            var bookmarks = [Bookmark]()
            for bookmark in database.objects(Bookmark.self).sorted(byKeyPath: "date", ascending: false) {
                guard bookmarks.count < 8 else {continue}
                bookmarks.append(bookmark)
            }
            let bookmarksData = bookmarks.compactMap { (bookmark) -> [String: Any]? in
                guard let zimFile = bookmark.zimFile, let url = URL(bookID: zimFile.id, contentPath: bookmark.path) else {return nil}
                return [
                    "title": bookmark.title,
                    "url": url.absoluteString,
                    "thumbImageData": bookmark.thumbImageData ?? bookmark.zimFile?.icon ?? Data()
                ]
            }
            UserDefaults(suiteName: "group.kiwix")?.set(bookmarksData, forKey: "bookmarks")
            NCWidgetController().setHasContent(bookmarks.count > 0, forWidgetWithBundleIdentifier: "self.Kiwix.Bookmarks")
        } catch {}
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
            guard let url = currentWebController?.currentURL, let zimFileID = url.host else {return}
            let path = url.path
            
            do {
                let database = try Realm(configuration: Realm.defaultConfig)
                let predicate = NSPredicate(format: "zimFile.id == %@ AND path == %@", zimFileID, path)
                if let bookmark = database.objects(Bookmark.self).filter(predicate).first {
                    presentBookmarkHUDController(isBookmarked: false, completion: nil)
                    try database.write {
                        database.delete(bookmark)
                    }
                } else {
                    guard let zimFile = database.object(ofType: ZimFile.self, forPrimaryKey: zimFileID),
                        let webController = currentWebController else {return}
                    let bookmark = Bookmark()
                    bookmark.zimFile = zimFile
                    bookmark.path = path
                    bookmark.title = webController.currentTitle ?? ""
                    bookmark.date = Date()
                    
                    let gathering = DispatchGroup()
                    
                    gathering.enter()
                    webController.extractSnippet(completion: { (snippet) in
                        bookmark.snippet = snippet
                        gathering.leave()
                    })
                    
                    if zimFile.hasPicture {
                        gathering.enter()
                        webController.extractImageURLs(completion: { (urls) in
                            bookmark.thumbImagePath = urls.first?.path
                            gathering.leave()
                        })
                    }
                    
                    gathering.notify(queue: .main, execute: {
                        self.presentBookmarkHUDController(isBookmarked: true, completion: nil)
                        do {
                            let database = try Realm(configuration: Realm.defaultConfig)
                            try database.write {
                                database.add(bookmark)
                            }
                        } catch {}
                    })
                }
            } catch {return}
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
    
    private func presentBookmarkHUDController(isBookmarked: Bool, completion: (() -> Void)?) {
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
            self.bookmarkButtonItem.button.isBookmarked = isBookmarked
            self.updateBookmarkWidgetData()
        })
    }
}
