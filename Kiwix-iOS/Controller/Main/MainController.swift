//
//  MainController.swift
//  Kiwix
//
//  Created by Chris Li on 11/13/16.
//  Copyright © 2016 Wikimedia CH. All rights reserved.
//

import UIKit

class MainController: UIViewController {
    
    let searchBar = SearchBar()
    let toolBarController = ToolbarController()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.titleView = searchBar
        showWelcome()
        
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass ||
            traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass else {return}
        switch traitCollection.horizontalSizeClass {
        case .compact:
            configureInterfaceForHorizontalCompact()
        case .regular:
            configureInterfaceForHorizontalRegular()
        default:
            return
        }
    }
    
    func configureInterfaceForHorizontalCompact() {
        navigationController?.setToolbarHidden(false, animated: false)
        
    }
    
    func configureInterfaceForHorizontalRegular() {
        navigationController?.setToolbarHidden(true, animated: false)
    }
    
    // MARK: - Show / Hide
    
    func showWelcome() {
        let controller = Controllers.welcome
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(controller)
        view.addSubview(controller.view)
        let views = ["view": controller.view]
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: .alignAllTop, metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: .alignAllLeft, metrics: nil, views: views))
        controller.didMove(toParentViewController: self)
    }
    
    func hideWelcome() {
        let controller = childViewControllers.flatMap({$0 as? WelcomeController}).first
        controller?.removeFromParentViewController()
        controller?.view.removeFromSuperview()
    }
    
}
