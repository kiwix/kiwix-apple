//
//  MainViewController.swift
//  Kiwix
//
//  Created by Chris Li on 11/7/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class MainViewController: UIViewController, UISearchControllerDelegate {
    let searchController = UISearchController(searchResultsController: SearchResultController())
    
    private lazy var cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelSearch))
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureSearchController()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass else {return}
        switch self.traitCollection.horizontalSizeClass {
        case .compact:
            if UIDevice.current.userInterfaceIdiom == .pad {
                navigationItem.setRightBarButton(searchController.isActive ? cancelButton : nil, animated: false)
            }
        case .regular:
            navigationItem.setRightBarButton(nil, animated: false)
        case .unspecified:
            break
        }
    }
    
    private func configureSearchController() {
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.autocorrectionType = .no
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.obscuresBackgroundDuringPresentation = true
        searchController.delegate = self
        searchController.searchResultsUpdater = searchController.searchResultsController as? SearchResultController
        navigationItem.titleView = searchController.searchBar
        self.definesPresentationContext = true
    }
    
    @objc func cancelSearch() {
        searchController.isActive = false
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
