//
//  SearchResultTabController.swift
//  iOS
//
//  Created by Chris Li on 4/19/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit

class SearchResultContainerController: UITabBarController {
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
