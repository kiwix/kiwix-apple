//
//  ViewController.swift
//  WikiMed
//
//  Created by Chris Li on 9/6/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import WebKit

class MainController: UIViewController, UISearchBarDelegate, ToolBarControlEvents {
    let searchBar = UISearchBar()
    let searchController = SearchController()
    
    private(set) var currentTab: TabController?
    private(set) var tabs = [UIViewController]()
    let toolBarController = ToolBarController()
    
    private lazy var libraryController = LibraryController()
    
    lazy var cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelSearch))
    
    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSearch()
        configureToolBar()
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
    
    func configureToolBar() {
        toolBarController.delegate = self
        addChildViewController(toolBarController)
        let toolBar = toolBarController.view!
        toolBar.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(toolBar, at: 0)
        if #available(iOS 11.0, *) {
            view.addConstraints([
                view.safeAreaLayoutGuide.centerXAnchor.constraint(equalTo: toolBar.centerXAnchor),
                view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: toolBar.bottomAnchor, constant: 10)])
        } else {
            view.addConstraints([
                view.centerXAnchor.constraint(equalTo: toolBar.centerXAnchor),
                view.bottomAnchor.constraint(equalTo: toolBar.bottomAnchor, constant: 10)])
        }
        toolBarController.didMove(toParentViewController: self)
    }
    
    func addTab() {
        if tabs.count == 0 {
            if #available(iOS 11.0, *) {
                tabs.append(WebKitTabController())
            } else {
                tabs.append(LegacyTabController())
            }
        }
        
        guard let tab = tabs.first else {return}
        currentTab = tab as? TabController
        addChildViewController(tab)
        tab.view.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(tab.view, belowSubview: toolBarController.view)
        view.addConstraints([
            view.topAnchor.constraint(equalTo: tab.view.topAnchor),
            view.leftAnchor.constraint(equalTo: tab.view.leftAnchor),
            view.bottomAnchor.constraint(equalTo: tab.view.bottomAnchor),
            view.rightAnchor.constraint(equalTo: tab.view.rightAnchor)])
        tab.didMove(toParentViewController: self)
    }
    
    @objc func cancelSearch() {
        searchBar.resignFirstResponder()
    }
    
    // MARK: - ToolBar
    
    func backButtonTapped() {
        currentTab?.goBack()
    }
    
    func forwardButtonTapped() {
        currentTab?.goForward()
    }
    
    func homeButtonTapped() {
        currentTab?.loadMainPage()
    }
    
    func libraryButtonTapped() {
        present(libraryController, animated: true, completion: nil)
    }
    
    private func updateToolBarButtons() {
        toolBarController.back.tintColor = webView.canGoBack ? nil : UIColor.gray
        toolBarController.forward.tintColor = webView.canGoForward ? nil : UIColor.gray
    }
    
    // MARK: - SearchBar
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.text = searchController.searchText
        return true
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        DispatchQueue.main.async {
            if let textField = searchBar.value(forKey: "searchField") as? UITextField {
                textField.selectAll(nil)
            }
            self.navigationItem.setRightBarButton(self.cancelButton, animated: true)
        }
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

class BaseController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissController))
    }
    
    @objc func dismissController() {
        dismiss(animated: true, completion: nil)
    }
}
