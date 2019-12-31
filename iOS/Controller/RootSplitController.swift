//
//  MainController_iOS13.swift
//  iOS
//
//  Created by Chris Li on 11/24/19.
//  Copyright © 2019 Chris Li. All rights reserved.
//

import UIKit

class RootSplitController: UISplitViewController, UISplitViewControllerDelegate {
    let sideBarViewController = SideBarController()
    let contentViewController = ContentViewController()
    
    init() {
        super.init(nibName: nil, bundle: nil)
        preferredDisplayMode = .allVisible
        
        let contentNavController = UINavigationController(rootViewController: contentViewController)
        contentNavController.isToolbarHidden = false
        viewControllers = [sideBarViewController, contentNavController]
        
        delegate = self
        sideBarViewController.favoriteController.delegate = contentViewController
        sideBarViewController.outlineController.delegate = contentViewController
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func overrideTraitCollection(forChild childViewController: UIViewController) -> UITraitCollection? {
        let traitCollection = super.overrideTraitCollection(forChild: childViewController)
        if viewControllers.count > 1,
            childViewController == viewControllers.last,
            preferredDisplayMode == .allVisible {
            return UITraitCollection(horizontalSizeClass: .compact)
        }
        return traitCollection
    }
    
    // MARK: UISplitViewControllerDelegate
    
    func primaryViewController(forExpanding splitViewController: UISplitViewController) -> UIViewController? {
        return sideBarViewController
    }
    
    func primaryViewController(forCollapsing splitViewController: UISplitViewController) -> UIViewController? {
        contentViewController.configureToolbar()
        let navigationController = UINavigationController(rootViewController: contentViewController)
        navigationController.isToolbarHidden = false
        return navigationController
    }
    
    func splitViewController(_ splitViewController: UISplitViewController,
                             separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        contentViewController.configureToolbar()
        let navigationController = UINavigationController(rootViewController: contentViewController)
        navigationController.isToolbarHidden = false
        return navigationController
    }
}
