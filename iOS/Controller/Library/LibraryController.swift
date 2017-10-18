//
//  LibraryController.swift
//  Kiwix
//
//  Created by Chris Li on 10/10/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class LibraryController: UISplitViewController, UISplitViewControllerDelegate {
    init() {
        super.init(nibName: nil, bundle: nil)
        viewControllers = [
            UINavigationController(rootViewController: LibraryMasterController()),
            UINavigationController(rootViewController: LibraryBlankDetailController())]
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
