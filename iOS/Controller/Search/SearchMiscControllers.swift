//
//  SearchMiscControllers.swift
//  iOS
//
//  Created by Chris Li on 4/19/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit

class SearchOnboardingController: UIViewController {
    override func loadView() {
        view = EmptyContentView(image: #imageLiteral(resourceName: "MagnifyingGlass"), title: "Download some books to get started")
    }
}

class SearchInProgressController: UIViewController {
    let indicator = UIActivityIndicatorView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        indicator.style = .gray
        indicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(indicator)
        indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        indicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        indicator.startAnimating()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        indicator.stopAnimating()
    }
}

class SearchNoResultController: UIViewController {
    override func loadView() {
        view = EmptyContentView(image: #imageLiteral(resourceName: "MagnifyingGlass"), title: "No Result")
    }
}
