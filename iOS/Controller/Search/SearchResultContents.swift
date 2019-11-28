//
//  SearchResultTabController.swift
//  iOS
//
//  Created by Chris Li on 4/19/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit

class SearchResultContents: UITabBarController {
    enum Mode {
        case onboarding, noText, inProgress, results, noResult
        
        var canScroll: Bool {
            return self == .noText || self == .results
        }
    }
    
    private let modes: [Mode] = [.noText, .results, .inProgress, .noResult, .onboarding]
    
    var mode: Mode = .noText {
        didSet {
            guard let index = modes.firstIndex(of: mode) else {return}
            selectedIndex = index
        }
    }
    
    let resultsListController = SearchResultsListController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.isHidden = true
        viewControllers = [
            SearchNoTextController(),
            resultsListController,
            SearchInProgressController(),
            SearchNoResultController(),
            SearchOnboardingController()
        ]
    }
}

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
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
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
