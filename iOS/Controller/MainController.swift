//
//  MainViewController.swift
//  Kiwix
//
//  Created by Chris Li on 11/7/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class MainController: UIViewController, UISearchControllerDelegate {
    private (set) var isShowingPanel = false
    @IBOutlet weak var dimView: DimView!
    private lazy var cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelSearchButtonTapped))
    private var webControllerObserver: NSKeyValueObservation? = nil

    // MARK: - Controllers
    
    let searchController = UISearchController(searchResultsController: SearchResultController())
    private(set) var tabsController: TabContainerController!
    private var panelController: PanelController!
    private(set) lazy var libraryController = LibraryController()
    
    // MARK: - Constraints
    
    @IBOutlet weak var panelCompactShowConstraint: NSLayoutConstraint!
    @IBOutlet weak var panelCompactHideConstraint: NSLayoutConstraint!
    @IBOutlet weak var panelRegularShowConstraint: NSLayoutConstraint!
    @IBOutlet weak var panelRegularHideConstraint: NSLayoutConstraint!
    @IBOutlet weak var separatorViewWidthConstraints: NSLayoutConstraint!
    
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
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: .UIApplicationWillEnterForeground, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        guard let identifier = segue.identifier else {return}
        switch identifier {
        case "TabContainerController":
            tabsController = segue.destination as! TabContainerController
            tabsController.delegate = self
        case "PanelController":
            panelController = segue.destination as! PanelController
            panelController.tableOfContent.delegate = self
            panelController.bookmark.delegate = self
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
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        view.setNeedsUpdateConstraints()
    }
    
    override func updateViewConstraints() {
        separatorViewWidthConstraints.constant = 1 / UIScreen.main.scale
        switch traitCollection.horizontalSizeClass {
        case .compact:
            NSLayoutConstraint.deactivate([panelRegularShowConstraint, panelRegularHideConstraint])
            panelCompactShowConstraint.isActive = isShowingPanel
            panelCompactHideConstraint.isActive = !isShowingPanel
        case .regular:
            NSLayoutConstraint.deactivate([panelCompactShowConstraint, panelCompactHideConstraint])
            panelRegularShowConstraint.isActive = isShowingPanel
            panelRegularHideConstraint.isActive = !isShowingPanel
        case .unspecified:
            break
        }
        super.updateViewConstraints()
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
        searchController.searchResultsUpdater = searchController.searchResultsController as? SearchResultController
        navigationItem.titleView = searchController.searchBar
        definesPresentationContext = true
    }
    
    func updateTableOfContents(completion: (() -> Void)? = nil) {
        guard panelController.tableOfContent.url != tabsController.webController?.currentURL,
            let webController = tabsController.webController else {completion?(); return}
        webController.extractTableOfContents(completion: { (currentURL, items) in
            self.panelController.tableOfContent.url = currentURL
            self.panelController.tableOfContent.items = items
            completion?()
        })
    }
    
    @objc func cancelSearchButtonTapped() {
        searchController.isActive = false
    }
    
    @objc func appWillEnterForeground() {
        DispatchQueue.main.async { self.configureToolbar() }
    }
    
    @IBAction func dimViewTapped(_ sender: UITapGestureRecognizer) {
        hidePanel()
        tableOfContentButtonItem.isFocused = false
        bookmarkButtonItem.isFocused = false
    }
    
    // MARK: - UISearchControllerDelegate
    
    func willPresentSearchController(_ searchController: UISearchController) {
        guard UIDevice.current.userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .compact else {return}
        navigationItem.setRightBarButton(cancelButton, animated: true)
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        guard UIDevice.current.userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .compact else {return}
        navigationItem.setRightBarButton(nil, animated: true)
    }
}

// MARK: - Panel Control

extension MainController: TableOfContentControllerDelegate, BookmarkControllerDelegate {
    func didTapTableOfContentItem(index: Int, item: TableOfContentItem) {
        tabsController.webController?.scrollToTableOfContentItem(index: index)
        if traitCollection.horizontalSizeClass == .compact {
            tableOfContentButtonItem.isFocused = false
            hidePanel()
        }
    }
    
    func didTapBookmark(articleURL: URL) {
        tabsController.load(url: articleURL)
    }
    
    func showPanel(mode: PanelMode) {
        panelController.set(mode: mode)
        
        guard !isShowingPanel else {return}
        isShowingPanel = true
        
        dimView.isHidden = false
        dimView.isDimmed = false
        
        view.layoutIfNeeded()
        view.setNeedsUpdateConstraints()
        self.navigationController?.setToolbarHidden(true, animated: true)
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseInOut, animations: {
            self.view.layoutIfNeeded()
            self.dimView.isDimmed = true
            if self.traitCollection.horizontalSizeClass == .compact {
                self.navigationController?.isToolbarHidden = true
            }
        })
    }
    
    func hidePanel() {
        panelController.set(mode: nil)
        
        guard isShowingPanel else {return}
        isShowingPanel = false
        
        view.layoutIfNeeded()
        view.setNeedsUpdateConstraints()
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseInOut, animations: {
            self.view.layoutIfNeeded()
            self.dimView.isDimmed = false
            if self.traitCollection.horizontalSizeClass == .compact {
                self.navigationController?.isToolbarHidden = false
            }
        }, completion: { _ in
            self.dimView.isHidden = true
        })
    }
}

// MARK: - Tab Control

extension MainController: TabContainerControllerDelegate {
    func tabDidFinishLoading(controller: WebViewController) {
        navigationBackButtonItem.button.isGrayed = !controller.canGoBack
        navigationForwardButtonItem.button.isGrayed = !controller.canGoForward
        if isShowingPanel && panelController.mode == .tableOfContent {
            updateTableOfContents()
        }
        if let url = tabsController.webController?.currentURL,
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
        } else if traitCollection.horizontalSizeClass == .compact {
            navigationController?.isToolbarHidden = false
            toolbarItems = [navigationBackButtonItem, navigationForwardButtonItem, tableOfContentButtonItem, bookmarkButtonItem, libraryButtonItem, settingButtonItem].enumerated()
                .reduce([], { $0 + ($1.offset > 0 ? [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), $1.element] : [$1.element]) })
            if searchController.isActive {
                navigationItem.setRightBarButton(cancelButton, animated: false)
            }
            if isShowingPanel {
                self.navigationController?.isToolbarHidden = true
            }
        }
    }
    
    func buttonTapped(item: BarButtonItem, button: UIButton) {
        switch item {
        case navigationBackButtonItem:
            tabsController.webController?.goBack()
        case navigationForwardButtonItem:
            tabsController.webController?.goForward()
        case tableOfContentButtonItem:
            item.isFocused = !item.isFocused
            if item.isFocused {
                bookmarkButtonItem.isFocused = false
                updateTableOfContents(completion: {
                    self.showPanel(mode: .tableOfContent)
                })
            } else {
                hidePanel()
            }
        case bookmarkButtonItem:
            item.isFocused = !item.isFocused
            if item.isFocused {
                tableOfContentButtonItem.isFocused = false
                showPanel(mode: .bookmark)
            } else {
                hidePanel()
            }
        case libraryButtonItem:
            present(libraryController, animated: true, completion: nil)
        case settingButtonItem:
            break
        default:
            break
        }
    }
    
    func buttonLongPresse(item: BarButtonItem, button: UIButton) {
        switch item {
        case bookmarkButtonItem:
            let context = CoreDataContainer.shared.viewContext
            guard let item = item as? BookmarkButtonItem,
                let webController = tabsController.webController,
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
