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
    let searchResultController = SearchResultController()
    let tab = LegacyTabController()
    
    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSearch()
        addTab()
    }
    
    func configureSearch() {
        let searchBar = UISearchBar()
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
    
    // MARK: - UISearchBarDelegate
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    }
    
    func showSearchController() {
        
    }
    
    func hideSearchController() {
        
    }
    
}

