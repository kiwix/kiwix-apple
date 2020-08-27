//
//  ContentController.swift
//  Kiwix
//
//  Created by Chris Li on 12/8/19.
//  Copyright © 2019 Chris Li. All rights reserved.
//

import UIKit
import RealmSwift

class ContentController: UIViewController, UISearchControllerDelegate, UIAdaptivePresentationControllerDelegate {
    let searchController: UISearchController
    private let searchResultsController: SearchResultsController
    private lazy var searchCancelButton = UIBarButtonItem(
        barButtonSystemItem: .cancel, target: self, action: #selector(cancelSearch))
    private let welcomeController = UIStoryboard(name: "Main", bundle: nil)
        .instantiateViewController(withIdentifier: "WelcomeController") as! WelcomeController
    
    
    // MARK:- Initialization
    
    init() {
        self.searchResultsController = SearchResultsController()
        self.searchController = UISearchController(searchResultsController: self.searchResultsController)
        
        super.init(nibName: nil, bundle: nil)
        
        // view background
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        
        // search controller
        searchController.delegate = self
        searchController.searchBar.autocorrectionType = .no
        searchController.searchBar.autocapitalizationType = .none
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchResultsUpdater = searchResultsController
        if #available(iOS 13.0, *) {
            searchController.automaticallyShowsCancelButton = false
            searchController.showsSearchResultsController = true
        } else {
            searchController.searchBar.searchBarStyle = .minimal
        }
        
        // misc
        definesPresentationContext = true
        navigationItem.hidesBackButton = true
        navigationItem.titleView = searchController.searchBar
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // show welcome controller
        setChildControllerIfNeeded(welcomeController)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isToolbarHidden = false
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    // MARK: - View and Controller Management
    
    func dismissPopoverController() {
        guard let style = presentedViewController?.modalPresentationStyle, style == .popover else { return }
        presentedViewController?.dismiss(animated: false)
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
    
    func setChildControllerIfNeeded(_ newChild: UIViewController?) {
        if let newChild = newChild, children.contains(newChild) {return}
        
        for child in children {
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
        
        if let child = newChild {
            child.view.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(child.view)
            if child == welcomeController {
                NSLayoutConstraint.activate([
                    view.topAnchor.constraint(equalTo: child.view.topAnchor),
                    view.leftAnchor.constraint(equalTo: child.view.leftAnchor),
                    view.bottomAnchor.constraint(equalTo: child.view.bottomAnchor),
                    view.rightAnchor.constraint(equalTo: child.view.rightAnchor),
                ])
            } else {
                NSLayoutConstraint.activate([
                    view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: child.view.topAnchor),
                    view.leftAnchor.constraint(equalTo: child.view.leftAnchor),
                    view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: child.view.bottomAnchor),
                    view.rightAnchor.constraint(equalTo: child.view.rightAnchor),
                ])
            }
            addChild(child)
            child.didMove(toParent: self)
        }
    }
    
    func presentBookmarkHUDController(isBookmarked: Bool) {
        let controller = HUDController()
        controller.modalPresentationStyle = .custom
        controller.transitioningDelegate = controller
        controller.direction = isBookmarked ? .down : .up
        controller.imageView.image = isBookmarked ? #imageLiteral(resourceName: "StarAdd") : #imageLiteral(resourceName: "StarRemove")
        controller.label.text = isBookmarked ?
            NSLocalizedString("Added", comment: "Bookmark HUD") :
            NSLocalizedString("Removed", comment: "Bookmark HUD")
        
        splitViewController?.present(controller, animated: true, completion: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                controller.dismiss(animated: true, completion: nil)
            })
            guard let rootController = self.splitViewController as? RootController else { return }
            rootController.bookmarkButton.isBookmarked = isBookmarked
            rootController.bookmarkToggleButton.isBookmarked = isBookmarked
        })
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
    
    func webViewDidFinishNavigation(controller: WebViewController) {
        guard let rootController = splitViewController as? RootController else { return }
        
        // if outline view is visible, update outline items
        if let rootController = splitViewController as? RootController,
            !rootController.isCollapsed,
            rootController.displayMode != .primaryHidden {
            let selectedNavController = rootController.sideBarController.selectedViewController
            let selectedController = (selectedNavController as? UINavigationController)?.topViewController
            if let outlineController = selectedController as? OutlineController {
                outlineController.update()
            }
        }
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
}
