//
//  ContentViewController.swift
//  iOS
//
//  Created by Chris Li on 12/8/19.
//  Copyright © 2019 Chris Li. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
class ContentViewController: UIViewController, UISearchControllerDelegate, WebViewControllerDelegate,
    OutlineControllerDelegate, FavoriteControllerDelegate {
    lazy var chevronLeftButton = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(goBack))
    lazy var chevronRightButton = UIBarButtonItem(image: UIImage(systemName: "chevron.right"), style: .plain, target: self, action: #selector(goForward))
    lazy var favoriteButton = UIBarButtonItem(image: UIImage(systemName: "star"), style: .plain, target: self, action: #selector(openFavorite))
    lazy var favoriteButton2 = FavoriteBarButtonItem(target: self, action: #selector(openFavorite))
    
    let searchController: UISearchController
    private let searchResultsController: SearchResultsController
    private lazy var searchCancelButton = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                          target: self,
                                                          action: #selector(cancelSearch))
    private var webViewControllers: [WebKitWebController] = []
    var currentWebViewController: WebKitWebController? { return webViewControllers.first }
    
    init() {
        self.searchResultsController = SearchResultsController()
        self.searchController = UISearchController(searchResultsController: self.searchResultsController)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.hidesBackButton = true
        navigationItem.titleView = searchController.searchBar
        definesPresentationContext = true
        view.backgroundColor = .systemBackground
        searchController.delegate = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.automaticallyShowsCancelButton = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.showsSearchResultsController = true
        searchController.searchResultsUpdater = searchResultsController
        
        configureToolbar()
        createNewTab()
    }
    
    func load(url: URL) {
        setChildControllerIfNeeded(currentWebViewController)
        currentWebViewController?.load(url: url)
    }
    
    // MARK: - View and Controller Management
    
    func configureToolbar() {
        if splitViewController?.isCollapsed == true {
            toolbarItems = [
                chevronLeftButton,
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                chevronRightButton,
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                UIBarButtonItem(image: UIImage(systemName: "list.bullet"), style: .plain, target: self, action: #selector(openOutline)),
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                favoriteButton2,
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                UIBarButtonItem(image: UIImage(systemName: "folder"), style: .plain, target: self, action: #selector(openLibrary)),
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                UIBarButtonItem(image: UIImage(systemName: "gear"), style: .plain, target: self, action: #selector(openSettings)),
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                UIBarButtonItem(image: UIImage(systemName: "square.on.square"), style: .plain, target: self, action: #selector(openTabsView)),
            ]
        } else {
            toolbarItems = [
                UIBarButtonItem(image: UIImage(systemName: "sidebar.left"), style: .plain, target: self, action: #selector(toggleSideBar)),
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                chevronLeftButton,
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                chevronRightButton,
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                favoriteButton,
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                UIBarButtonItem(image: UIImage(systemName: "folder"), style: .plain, target: self, action: #selector(openLibrary)),
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                UIBarButtonItem(image: UIImage(systemName: "gear"), style: .plain, target: self, action: #selector(openSettings)),
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                UIBarButtonItem(image: UIImage(systemName: "square.on.square"), style: .plain, target: self, action: #selector(openTabsView)),
            ]
        }
    }
    
    private func createNewTab() {
        let controller = WebKitWebController()
        webViewControllers.append(controller)
        switchToTab(controller: controller)
    }
    
    private func switchToTab(controller: WebViewController) {
        var controller = controller
        controller.delegate = self
        
        chevronLeftButton.isEnabled = controller.canGoBack
        chevronRightButton.isEnabled = controller.canGoForward
    }
    
    private func setView(_ subView: UIView?) {
        view.subviews.forEach({ $0.removeFromSuperview() })
        if let subView = subView {
            subView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(subView)
            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: subView.topAnchor),
                view.leftAnchor.constraint(equalTo: subView.leftAnchor),
                view.bottomAnchor.constraint(equalTo: subView.bottomAnchor),
                view.rightAnchor.constraint(equalTo: subView.rightAnchor),
            ])
        }
    }
    
    private func setChildControllerIfNeeded(_ newChild: UIViewController?) {
        if let newChild = newChild, children.contains(newChild) {return}
        
        for child in children {
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
        
        if let child = newChild {
            child.view.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(child.view)
            NSLayoutConstraint.activate([
                topLayoutGuide.bottomAnchor.constraint(equalTo: child.view.topAnchor),
                view.leftAnchor.constraint(equalTo: child.view.leftAnchor),
                bottomLayoutGuide.topAnchor.constraint(equalTo: child.view.bottomAnchor),
                view.rightAnchor.constraint(equalTo: child.view.rightAnchor),
            ])
            addChild(child)
            child.didMove(toParent: self)
        }
    }
    
    // MARK: - UISearchControllerDelegate
    
    func willPresentSearchController(_ searchController: UISearchController) {
        navigationItem.setRightBarButton(searchCancelButton, animated: true)
        navigationController?.isToolbarHidden = true
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        navigationItem.setRightBarButton(nil, animated: true)
        navigationController?.isToolbarHidden = false
    }
    
    // MARK: WebViewControllerDelegate
    
    func webViewDidTapOnGeoLocation(controller: WebViewController, url: URL) {
        
    }
    
    func webViewDidFinishLoading(controller: WebViewController) {
        // update buttons
        chevronLeftButton.isEnabled = controller.canGoBack
        chevronRightButton.isEnabled = controller.canGoForward
//        favoriteButton
        
        // if outline view is visible, update outline items
        if let rootSplitController = splitViewController as? RootSplitController,
            !rootSplitController.isCollapsed,
            rootSplitController.displayMode != .primaryHidden {
            let selectedNavController = rootSplitController.sideBarViewController.selectedViewController
            let selectedController = (selectedNavController as? UINavigationController)?.topViewController
            if let outlineController = selectedController as? OutlineController {
                outlineController.updateContent()
            }
        }
    }
    
    // MARK: OutlineControllerDelegate
    
    func didTapOutlineItem(index: Int, item: TableOfContentItem) {
        currentWebViewController?.scrollToTableOfContentItem(index: index)
    }
    
    // MARK: FavoriteControllerDelegate
    
    func didTapFavorite(url: URL) {
        load(url: url)
    }
    
    func didDeleteFavorite(url: URL) {
        
    }
    
    // MARK: - Actions
    
    @objc func cancelSearch() {
        /*
         We have to dismiss the `searchController` first, so that the `isBeingDismissed` property is correct on the
         `searchResultsController`. We rely on `isBeingDismissed` to understand if the search text is cleared because
         of user tapped cancel button or manually cleared the serach field.
         */
        searchController.dismiss(animated: true)
        searchController.isActive = false
    }
    
    @objc func toggleSideBar() {
        UIView.animate(withDuration: 0.2) {
            let current = self.splitViewController?.preferredDisplayMode
            self.splitViewController?.preferredDisplayMode = current == .primaryHidden ? .allVisible : .primaryHidden
        }
    }
    
    @objc func goBack() {
        currentWebViewController?.goBack()
    }
    
    @objc func goForward() {
        currentWebViewController?.goForward()
    }
    
    @objc func openOutline() {
        let outlineController = OutlineController()
        let navigationController = UINavigationController(rootViewController: outlineController)
        outlineController.delegate = self
        splitViewController?.present(navigationController, animated: true)
    }
    
    @objc func openFavorite(sender: UIBarButtonItem, forEvent event: UIEvent) {
        guard let touch = event.allTouches?.first else {return}
        if touch.tapCount == 1 {
            let favoriteController = FavoriteController()
            let navigationController = UINavigationController(rootViewController: favoriteController)
            favoriteController.delegate = self
            splitViewController?.present(navigationController, animated: true)
        } else if touch.tapCount == 0 {
            print("long pressed")
        }
    }
    
    @objc func openLibrary() {
        guard let splitController = splitViewController as? RootSplitController else {return}
        splitController.present(splitController.libraryController, animated: true)
    }
    
    @objc func openSettings() {
        splitViewController?.present(SettingNavigationController(), animated: true)
    }
    
    @objc func openTabsView() {
        splitViewController?.present(TabsController(), animated: true)
    }
}

// MARK: - BarButton

@available(iOS 13.0, *)
class FavoriteBarButtonItem: UIBarButtonItem {
    var button: UIButton {
        get {return customView as! UIButton}
    }
    
    convenience init(target: Any, action: Selector) {
        self.init(customView: UIButton())
        button.addTarget(target, action: action, for: .touchUpInside)
        button.setImage(UIImage(systemName: "star"), for: .normal)
        button.setImage(UIImage(systemName: "star.slash.fill"), for: .highlighted)
    }
}
