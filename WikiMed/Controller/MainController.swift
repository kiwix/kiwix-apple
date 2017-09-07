//
//  ViewController.swift
//  WikiMed
//
//  Created by Chris Li on 9/6/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import WebKit

class MainController: UIViewController {
    let tab = LegacyTabViewViewController()
    
    @IBOutlet weak var webView: UIWebView!
    override func viewDidLoad() {
        super.viewDidLoad()
        addTab()
        
        let search = UISearchBar()
        search.placeholder = "Search"
        search.searchBarStyle = .minimal
        navigationItem.titleView = search
    }
    
    func addTab() {
        addChildViewController(tab)
        tab.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tab.view)
        
        view.addConstraint(NSLayoutConstraint(item: tab.view, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: 0.0))
        view.addConstraint(NSLayoutConstraint(item: tab.view, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 0.0))
        view.addConstraint(NSLayoutConstraint(item: tab.view, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: 0.0))
        view.addConstraint(NSLayoutConstraint(item: tab.view, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0.0))
        
        tab.didMove(toParentViewController: self)
    }
    
}

