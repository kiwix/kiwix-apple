//
//  BookmarkSplitController.swift
//  Kiwix
//
//  Created by Chris Li on 1/12/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class BookmarkSplitController: UISplitViewController, UISplitViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        preferredDisplayMode = .allVisible
        minimumPrimaryColumnWidth = 320.0
        delegate = self
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        guard traitCollection != previousTraitCollection else {return}
        let controller: CoreDataTableBaseController? = {
            let nav = viewControllers.first as? UINavigationController
            return nav?.topViewController as? CoreDataTableBaseController
        }()
        controller?.tableView.indexPathsForVisibleRows?.forEach({ (indexPath) in
            guard let cell = controller?.tableView.cellForRow(at: indexPath) else {return}
            controller?.configureCell(cell, atIndexPath: indexPath)
        })
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return true
    }
}
