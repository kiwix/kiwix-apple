//
//  MainControllerShowHide.swift
//  Kiwix
//
//  Created by Chris Li on 7/20/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

extension MainController {
    
    // MARK: - Show/Hide Search
    
    func showSearch(animated: Bool) {
        // Hide any presenting controller
        presentedViewController?.dismiss(animated: animated, completion: nil)
        
        // Hide TOC
        if isShowingTableOfContents && traitCollection.horizontalSizeClass == .compact {
            hideTableOfContentsController()
        }
        
        // Hide ToolBar &
        navigationController?.setToolbarHidden(true, animated: animated)
        
        // Show Search Result Controller
        showSearchResultController(animated: animated)
        
        // SearchBar
        if !searchBar.isFirstResponder {searchBar.becomeFirstResponder()}
        
        // Show Cancel Button If Needed
        if traitCollection.horizontalSizeClass == .compact {
            if UIDevice.current.userInterfaceIdiom == .pad {
                navigationItem.setRightBarButton(cancelButton, animated: animated)
            } else if UIDevice.current.userInterfaceIdiom == .phone {
//                searchBar.setShowsCancelButton(true, animated: animated)
            }
        }
    }
    
    func hideSearch(animated: Bool) {
        // Hide Search Result Controller
        hideSearchResultController(animated: true)
        
        if searchBar.isFirstResponder {searchBar.resignFirstResponder()}
        
        // Hide Cancel Button If Needed
        if traitCollection.horizontalSizeClass == .compact {
            if UIDevice.current.userInterfaceIdiom == .pad {
                navigationItem.setRightBarButton(nil, animated: animated)
            } else if UIDevice.current.userInterfaceIdiom == .phone {
//                searchBar.setShowsCancelButton(false, animated: animated)
            }
        }
    }
    
    fileprivate func showSearchResultController(animated: Bool) {
        let controller = Controllers.search
        guard !childViewControllers.contains(controller) else {return}
        addChildViewController(controller)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controller.view)
        
        let views = ["SearchController": controller.view]
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[SearchController]|", options: .alignAllCenterY, metrics: nil, views: views))
        
        view.addConstraint(controller.view.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor))
        view.addConstraint(controller.view.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor))
        
        if animated {
            controller.view.alpha = 0.5
            controller.view.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
            UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseOut, animations: { () -> Void in
                controller.view.alpha = 1.0
                controller.view.transform = CGAffineTransform.identity
            }, completion: nil)
        } else {
            controller.view.alpha = 1.0
            controller.view.transform = CGAffineTransform.identity
        }
        controller.didMove(toParentViewController: self)
    }
    
    fileprivate func hideSearchResultController(animated: Bool) {
        guard let searchController = childViewControllers.flatMap({$0 as? SearchController}).first else {return}
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
                searchController.view.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
                }, completion: completion)
        } else {
            completion(true)
        }
    }
    
    // MARK: - Show/Hide TOC
    
    func showTableOfContentsController() {
        isShowingTableOfContents = true
        tocVisiualEffectView.isHidden = false
        dimView.isHidden = false
        dimView.alpha = 0.0
        view.layoutIfNeeded()
        
        configureTableOfContents()
        configureTOCViewConstraints()
        
        UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.0, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
            self.dimView.alpha = 0.5
        }) { (completed) in }
        
        JS.startTOCCallBack(webView)
    }
    
    func hideTableOfContentsController() {
        isShowingTableOfContents = false
        view.layoutIfNeeded()
        configureTOCViewConstraints()
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseIn, animations: {
            self.view.layoutIfNeeded()
            self.dimView.alpha = 0.0
        }) { (completed) in
            self.dimView.isHidden = true
            self.tocVisiualEffectView.isHidden = true
        }
        
        JS.stopTOCCallBack(webView)
    }
    
    func configureTOCViewConstraints() {
        switch traitCollection.horizontalSizeClass {
        case .compact:
            let tocHeight: CGFloat = {
                guard let controller = tableOfContentsController else {return floor(view.frame.height * 0.4)}
                let tocContentHeight = controller.tableView.contentSize.height
                guard controller.headings.count != 0 else {return floor(view.frame.height * 0.4)}
                let toolBarHeight: CGFloat = traitCollection.horizontalSizeClass == .regular ? 0.0 : (traitCollection.verticalSizeClass == .compact ? 32.0 : 44.0)
                return min(tocContentHeight + toolBarHeight, floor(view.frame.height * 0.65))
            }()
            tocHeightConstraint.constant = tocHeight
            tocTopToSuperViewBottomSpacing.constant = isShowingTableOfContents ? tocHeight : 0.0
        case .regular:
            tocLeadSpacing.constant = isShowingTableOfContents ? 0.0 : 270
            break
        default:
            break
        }
    }
    
    // MARK: - Show Bookmark
    
    func showBookmarkController() {
        let controller = Controllers.bookmark
        controller.modalPresentationStyle = .formSheet
        present(controller, animated: true, completion: nil)
    }
    
    // MARK: - Show/Hide Welcome
    
    func showWelcome() {
        let controller = Controllers.welcome
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(controller)
        view.addSubview(controller.view)
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: NSLayoutFormatOptions.alignAllTop, metrics: nil, views: ["view": controller.view]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: NSLayoutFormatOptions.alignAllLeft, metrics: nil, views: ["view": controller.view]))
        controller.didMove(toParentViewController: self)
    }
    
    func hideWelcome() {
        guard let controller = childViewControllers.flatMap({$0 as? WelcomeController}).first else {return}
        controller.removeFromParentViewController()
        controller.view.removeFromSuperview()
    }
    
    // MARK: - Show First Time Launch Alert
    
    func showGetStartedAlert() {
        guard !Preference.hasShowGetStartedAlert else {return}
//        let operation = GetStartedAlert(context: self)
//        GlobalQueue.shared.addOperation(operation)
    }
}
