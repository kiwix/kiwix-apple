//
//  MainController_iOS13.swift
//  iOS
//
//  Created by Chris Li on 11/24/19.
//  Copyright © 2019 Chris Li. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
class RootController: UIViewController {
    private let compactController = RootCompactController()
    private let regularController = RootRegularController()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupContent(traitCollection: traitCollection)
    }
    
    override func willTransition(to newCollection: UITraitCollection,
                                 with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        setupContent(traitCollection: newCollection)
    }
    
    private func setupContent(traitCollection: UITraitCollection) {
        switch traitCollection.horizontalSizeClass {
        case .compact:
            setChildController(compactController)
        case .regular:
            setChildController(regularController)
        default:
            setChildController(nil)
        }
    }
    
    private func setChildController(_ newChild: UIViewController?) {
        for child in children {
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
        
        if let child = newChild {
            child.view.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(child.view)
            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: child.view.topAnchor),
                view.leftAnchor.constraint(equalTo: child.view.leftAnchor),
                view.bottomAnchor.constraint(equalTo: child.view.bottomAnchor),
                view.rightAnchor.constraint(equalTo: child.view.rightAnchor),
            ])
            addChild(child)
            child.didMove(toParent: self)
        }
    }
}

class RootCompactController: UIViewController {
    
}

@available(iOS 13.0, *)
class RootRegularController: UISplitViewController {
    let masterController = SideBarController()
    let detailController = UINavigationController(rootViewController: ContentRegularController())
    
    init() {
        super.init(nibName: nil, bundle: nil)
        preferredDisplayMode = .allVisible
        viewControllers = [masterController, detailController]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func overrideTraitCollection(forChild childViewController: UIViewController) -> UITraitCollection? {
        let traitCollection = super.overrideTraitCollection(forChild: childViewController)
        if childViewController == detailController, preferredDisplayMode == .allVisible {
            return UITraitCollection(horizontalSizeClass: .compact)
        }
        return traitCollection
    }
}

@available(iOS 13.0, *)
class ContentRegularController: UIViewController, UISearchControllerDelegate {
    private let searchController = UISearchController(searchResultsController: SearchResultsController())
    private let searchResultsController = SearchResultsController()
    private lazy var searchCancelButton = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                          target: self,
                                                          action: #selector(cancelSearch))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.titleView = searchController.searchBar
        searchController.delegate = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.showsSearchResultsController = true
        searchController.searchResultsUpdater = searchResultsController
        definesPresentationContext = true
        
        navigationController?.isToolbarHidden = false
        toolbarItems = [
            UIBarButtonItem(image: UIImage(systemName: "sidebar.left"), style: .plain, target: self, action: #selector(toggleSideBar)),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        ]
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
        searchController.isActive = false
    }
    
    @objc func toggleSideBar() {
        UIView.animate(withDuration: 0.2) {
            let currentMode = self.splitViewController?.preferredDisplayMode
            self.splitViewController?.preferredDisplayMode = currentMode == .primaryHidden ? .allVisible : .primaryHidden
        }
    }
}
