//
//  MainController.swift
//  Kiwix
//
//  Created by Chris Li on 11/13/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit

class MainController: UIViewController {
    
    let searchBar = SearchBar()
    lazy var controllers = Controllers()
    lazy var buttons = Buttons()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.titleView = searchBar
        searchBar.delegate = self
        buttons.delegate = self
        
        showWelcome()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        buttons.addLongTapGestureRecognizer()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass ||
            traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass else {return}
        switch traitCollection.horizontalSizeClass {
        case .compact:
            navigationController?.setToolbarHidden(false, animated: false)
            navigationItem.leftBarButtonItems = nil
            navigationItem.rightBarButtonItems = nil
            if searchBar.isFirstResponder {
                navigationItem.rightBarButtonItem = buttons.cancel
            }
            toolbarItems = buttons.toolbar
        case .regular:
            navigationController?.setToolbarHidden(true, animated: false)
            toolbarItems = nil
            navigationItem.leftBarButtonItems = buttons.navLeft
            navigationItem.rightBarButtonItems = buttons.navRight
        default:
            return
        }
    }
    
    // MARK: - Show / Hide
    
    func showWelcome() {
        let controller = controllers.welcome
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
    
    func showSearch(animated: Bool) {
        let controller = controllers.search
        controller.delegate = self
        guard !childViewControllers.contains(controller) else {return}
        
        // add cancel button if needed
        if traitCollection.horizontalSizeClass == .compact {
            navigationItem.setRightBarButton(buttons.cancel, animated: animated)
        }
        
        // manage view hierarchy
        addChildViewController(controller)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controller.view)
        
        let views = ["SearchController": controller.view]
        view.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "H:|[SearchController]|", options: .alignAllCenterY, metrics: nil, views: views))
        view.addConstraint(controller.view.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor))
        view.addConstraint(controller.view.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor))
        
        if animated {
            controller.view.alpha = 0.5
            UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseOut, animations: { () -> Void in
                controller.view.alpha = 1.0
            }, completion: nil)
        } else {
            controller.view.alpha = 1.0
        }
        controller.didMove(toParentViewController: self)
    }
    
    func hideSearch(animated: Bool) {
        guard let searchController = childViewControllers.flatMap({$0 as? SearchContainer}).first else {return}
        
        // remove cancel button if needed
        if traitCollection.horizontalSizeClass == .compact {
            navigationItem.setRightBarButton(nil, animated: animated)
        }
        
        let completion = { (complete: Bool) -> Void in
            guard complete else {return}
            searchController.view.removeFromSuperview()
            searchController.removeFromParentViewController()
            guard self.traitCollection.horizontalSizeClass == .compact else {return}
            self.navigationController?.setToolbarHidden(false, animated: animated)
        }
        
        searchController.willMove(toParentViewController: nil)
        if animated {
            UIView.animate(withDuration: 0.15, delay: 0.0, options: .beginFromCurrentState, animations: {
                searchController.view.alpha = 0.0
            }, completion: completion)
        } else {
            completion(true)
        }
    }
    
}
