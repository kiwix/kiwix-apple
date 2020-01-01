//
//  MainController_iOS13.swift
//  iOS
//
//  Created by Chris Li on 11/24/19.
//  Copyright © 2019 Chris Li. All rights reserved.
//

import UIKit

class RootController: UISplitViewController, UISplitViewControllerDelegate {
    let sideBarViewController = SideBarController()
    let contentViewController = ContentViewController()
    let contentNavigationController: UINavigationController
    
    init() {
        self.contentNavigationController = UINavigationController(rootViewController: contentViewController)
        self.contentNavigationController.isToolbarHidden = false
        
        super.init(nibName: nil, bundle: nil)
        viewControllers = [sideBarViewController, self.contentNavigationController]
        
        delegate = self
        preferredDisplayMode = .allVisible
        sideBarViewController.favoriteController.delegate = contentViewController
        sideBarViewController.outlineController.delegate = contentViewController
        contentViewController.configureToolbar(isGrouped: !isCollapsed)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func overrideTraitCollection(forChild childViewController: UIViewController) -> UITraitCollection? {
        if viewControllers.count > 1,
            childViewController == viewControllers.last,
            preferredDisplayMode == .allVisible {
            return UITraitCollection(horizontalSizeClass: .compact)
        } else {
            return super.overrideTraitCollection(forChild: childViewController)
        }
    }
    
    // MARK: UISplitViewControllerDelegate
    
    func primaryViewController(forExpanding splitViewController: UISplitViewController) -> UIViewController? {
        return sideBarViewController
    }
    
    func primaryViewController(forCollapsing splitViewController: UISplitViewController) -> UIViewController? {
        contentViewController.configureToolbar(isGrouped: false)
        return contentNavigationController
    }
    
    func splitViewController(_ splitViewController: UISplitViewController,
                             separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        contentViewController.configureToolbar(isGrouped: true)
        return contentNavigationController
    }
}
