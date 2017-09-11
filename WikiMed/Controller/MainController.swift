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
    lazy var cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelSearch))
    
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
        searchBar.autocapitalizationType = .none
        searchBar.autocorrectionType = .no
        
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
    
    @objc func cancelSearch() {
        searchBar.resignFirstResponder()
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.text = searchController.searchText
        return true
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        DispatchQueue.main.async {
            if let textField = searchBar.value(forKey: "searchField") as? UITextField {
                textField.selectAll(nil)
            }
        }
        
        navigationItem.setRightBarButton(cancelButton, animated: true)
        showSearchController()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.text = nil
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
        let constraints = [
            searchResult.leftAnchor.constraint(equalTo: view.leftAnchor),
            searchResult.rightAnchor.constraint(equalTo: view.rightAnchor),
            searchResult.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ]
        view.addConstraints(constraints)
        if #available(iOS 11.0, *) {
            view.addConstraint(searchResult.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor))
        } else {
            view.addConstraint(searchResult.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor))
        }
        searchController.didMove(toParentViewController: self)
    }
    
    private func hideSearchController() {
        searchController.view.removeFromSuperview()
        searchController.removeFromParentViewController()
    }
    
}

