//
//  MainController_iOS13.swift
//  iOS
//
//  Created by Chris Li on 11/24/19.
//  Copyright © 2019 Chris Li. All rights reserved.
//

import UIKit
import WebKit

@available(iOS 13.0, *)
class TestController: UISplitViewController, UISplitViewControllerDelegate {
    let sideBarViewController = SideBarController()
    let contentViewController = ContentViewController()
    
    init() {
        super.init(nibName: nil, bundle: nil)
        preferredDisplayMode = .allVisible
        
        let contentNavController = UINavigationController(rootViewController: contentViewController)
        contentNavController.isToolbarHidden = false
        viewControllers = [sideBarViewController, contentNavController]
        
        delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func overrideTraitCollection(forChild childViewController: UIViewController) -> UITraitCollection? {
        let traitCollection = super.overrideTraitCollection(forChild: childViewController)
        if viewControllers.count > 1,
            childViewController == viewControllers.last,
            preferredDisplayMode == .allVisible {
            return UITraitCollection(horizontalSizeClass: .compact)
        }
        return traitCollection
    }
    
    // MARK: UISplitViewControllerDelegate
    
    func primaryViewController(forExpanding splitViewController: UISplitViewController) -> UIViewController? {
        return sideBarViewController
    }
    
    func primaryViewController(forCollapsing splitViewController: UISplitViewController) -> UIViewController? {
        let navigationController = UINavigationController(rootViewController: contentViewController)
        navigationController.isToolbarHidden = false
        return navigationController
    }
    
    func splitViewController(_ splitViewController: UISplitViewController,
                             separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        let navigationController = UINavigationController(rootViewController: contentViewController)
        navigationController.isToolbarHidden = false
        return navigationController
    }
}

@available(iOS 13.0, *)
class ContentViewController: UIViewController, UISearchControllerDelegate {
    let searchController: UISearchController
    private let searchResultsController: SearchResultsController
    private lazy var searchCancelButton = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                          target: self,
                                                          action: #selector(cancelSearch))
    private var webViewControllers = [WebKitWebController()]
    private var currentWebViewController: WebKitWebController {return webViewControllers[0]}
    
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
        searchController.delegate = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.showsSearchResultsController = true
        searchController.searchResultsUpdater = searchResultsController
        configureToolbar()
    }
    
    func load(url: URL) {
        setChildController(currentWebViewController)
        currentWebViewController.load(url: url)
    }
    
    // MARK: View Configuration
    
    private func configureToolbar() {
        toolbarItems = [
            UIBarButtonItem(image: UIImage(systemName: "sidebar.left"), style: .plain, target: self, action: #selector(toggleSideBar)),
            UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(goBack)),
            UIBarButtonItem(image: UIImage(systemName: "chevron.right"), style: .plain, target: self, action: #selector(goForward)),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(image: UIImage(systemName: "square.on.square"), style: .plain, target: self, action: #selector(toggleTabsView)),
        ]
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
    
    private func setChildController(_ newChild: UIViewController?) {
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
    
    // MARK: UISearchControllerDelegate
    
    func willPresentSearchController(_ searchController: UISearchController) {
        if UIDevice.current.userInterfaceIdiom == .pad {
            navigationItem.setRightBarButton(searchCancelButton, animated: true)
        }
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        if UIDevice.current.userInterfaceIdiom == .pad {
            navigationItem.setRightBarButton(nil, animated: true)
        }
    }
    
    // MARK: Actions
    
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
        currentWebViewController.goBack()
    }
    
    @objc func goForward() {
        currentWebViewController.goForward()
    }
    
    @objc func toggleTabsView() {
        
    }
    
    // MARK: Type Definition
    
    enum ContentMode {
        case web
        case welcome
        case empty
    }
}
