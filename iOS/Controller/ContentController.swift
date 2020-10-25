//
//  ContentController.swift
//  Kiwix
//
//  Created by Chris Li on 12/8/19.
//  Copyright © 2019 Chris Li. All rights reserved.
//

import SwiftUI
import UIKit
import RealmSwift

class ContentController: UIViewController, UISearchControllerDelegate, UIAdaptivePresentationControllerDelegate {
    let searchController: UISearchController
    private let searchResultsController: SearchResultsController
    private lazy var searchCancelButton = UIBarButtonItem(
        barButtonSystemItem: .cancel, target: self, action: #selector(dismissSearch))
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
        if #available(iOS 14.0, *), FeatureFlags.homeViewEnabled {
            var homeView = HomeView()
            homeView.libraryButtonTapped = { [unowned self] in
                guard let rootController = self.splitViewController as? RootController else { return }
                rootController.openLibrary()
            }
            homeView.settingsButtonTapped = { [unowned self] in
                guard let rootController = self.splitViewController as? RootController else { return }
                rootController.openSettings()
            }
            setChildControllerIfNeeded(UIHostingController(rootView: homeView))
        } else {
            setChildControllerIfNeeded(welcomeController)
        }
    }
    
    // MARK: - View and Controller Management
    
    private func setView(_ subView: UIView?) {
        view.subviews.forEach({ $0.removeFromSuperview() })
        guard let subView = subView else { return }
        subView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subView)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: subView.topAnchor),
            view.leftAnchor.constraint(equalTo: subView.leftAnchor),
            view.bottomAnchor.constraint(equalTo: subView.bottomAnchor),
            view.rightAnchor.constraint(equalTo: subView.rightAnchor),
        ])
    }
    
    func setChildControllerIfNeeded(_ newChild: UIViewController?) {
        if let newChild = newChild, children.contains(newChild) {return}
        
        for child in children {
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
        
        guard let child = newChild else { return }
        if child is WebViewController {
            addChild(child)
            view.subviews.forEach({ $0.removeFromSuperview() })
            child.view.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(child.view)
            NSLayoutConstraint.activate([
                view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: child.view.topAnchor),
                view.leftAnchor.constraint(equalTo: child.view.leftAnchor),
                view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: child.view.bottomAnchor),
                view.rightAnchor.constraint(equalTo: child.view.rightAnchor),
            ])
            child.didMove(toParent: self)
        } else if #available(iOS 14.0, *) {
            if child is UIHostingController<HomeView> {
                setView(child.view)
            } else {
                addChild(child)
                setView(child.view)
                child.didMove(toParent: self)
            }
        } else {
            addChild(child)
            setView(child.view)
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
    
    // MARK: - Actions
    
    @objc func dismissSearch() {
        /*
         We have to dismiss the `searchController` first, so that the `isBeingDismissed` property is correct on the
         `searchResultsController`. We rely on `isBeingDismissed` to understand if the search text is cleared because
         of user tapped cancel button or manually cleared the serach field.
         */
        searchController.dismiss(animated: true)
        searchController.isActive = false
    }
}
