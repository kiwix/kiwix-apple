//
//  ViewController.swift
//  WikiMed
//
//  Created by Chris Li on 9/6/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import WebKit

class MainController: UIViewController, UISearchBarDelegate {
    let searchController = SearchController()
    let tab = LegacyTabController()
    let searchBar = UISearchBar()
    lazy var cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(endSearch))
    
    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSearch()
        addTab()
    }
    
    func configureSearch() {
        searchBar.delegate = self
        searchBar.placeholder = NSLocalizedString("Search", comment: "Search Promot")
        searchBar.searchBarStyle = .minimal
        
        navigationItem.titleView = searchBar
    }
    
    func addTab() {
        addChildViewController(tab)
        tab.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tab.view)
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[tab]|", options: [], metrics: nil, views: ["tab": tab.view]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[tab]|", options: [], metrics: nil, views: ["tab": tab.view]))
        tab.didMove(toParentViewController: self)
    }
    
    @objc func endSearch() {
        searchBar.resignFirstResponder()
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        navigationItem.setRightBarButton(cancelButton, animated: true)
        showSearchController()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        navigationItem.setRightBarButton(nil, animated: true)
        hideSearchController()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchController.startSearch(text: searchText)
    }
    
    private func showSearchController() {
        addChildViewController(searchController)
        let searchResult = searchController.view!
        searchResult.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchResult)
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[searchResult]|", options: [], metrics: nil, views: ["searchResult": searchResult]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[topGuide]-(0)-[searchResult]|", options: [], metrics: nil, views: ["topGuide": topLayoutGuide, "searchResult": searchResult]))
        searchController.didMove(toParentViewController: self)
    }
    
    private func hideSearchController() {
        searchController.view.removeFromSuperview()
        searchController.removeFromParentViewController()
    }
    
}

