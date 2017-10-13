//
//  LibraryController.swift
//  Kiwix
//
//  Created by Chris Li on 10/10/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class LibraryController: UISplitViewController, UISplitViewControllerDelegate {
    let master  = LibraryMasterController()
    let detail = LibraryDetailController()
    
    init() {
        super.init(nibName: nil, bundle: nil)
        viewControllers = [UINavigationController(rootViewController: master), UINavigationController(rootViewController: detail)]
        delegate = self
        preferredDisplayMode = .allVisible
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return true
    }
}
