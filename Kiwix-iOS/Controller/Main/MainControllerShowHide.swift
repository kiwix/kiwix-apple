//
//  MainControllerShowHide.swift
//  Kiwix
//
//  Created by Chris Li on 7/20/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

extension MainController {
    
    func hidePresentedController(animated: Bool, completion: (() -> Void)? = nil) {
        guard let controller = presentedViewController else {
            completion?()
            return
        }
        controller.dismissViewControllerAnimated(animated, completion: completion)
    }
    
    // MARK: - Show/Hide Search
    
    func showSearch(animated animated: Bool) {
        navigationController?.setToolbarHidden(true, animated: animated)
        showSearchResultController(animated: animated)
        searchBar.placeholder = LocalizedStrings.search
        if !searchBar.isFirstResponder() {
            searchBar.becomeFirstResponder()
        }
        if traitCollection.horizontalSizeClass == .Compact {
            searchBar.setShowsCancelButton(true, animated: animated)
        }
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad && traitCollection.horizontalSizeClass == .Compact {
            navigationItem.setRightBarButtonItem(cancelButton, animated: animated)
        }
        if isShowingTableOfContents && traitCollection.horizontalSizeClass == .Compact {
            animateOutTableOfContentsController()
        }
    }
    
    func hideSearch(animated animated: Bool) {
        hideSearchResultController(animated: true)
        searchBar.setShowsCancelButton(false, animated: animated)
        searchBar.text = nil
        if searchBar.isFirstResponder() {
            searchBar.resignFirstResponder()
        }
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad && traitCollection.horizontalSizeClass == .Compact {
            navigationItem.setRightBarButtonItem(nil, animated: animated)
        }
    }
    
    private func showSearchResultController(animated animated: Bool) {
        guard let searchController = searchController ?? UIStoryboard.search.instantiateInitialViewController() as? SearchController else {return}
        self.searchController = searchController
        guard !childViewControllers.contains(searchController) else {return}
        addChildViewController(searchController)
        searchController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchController.view)
        
        let views = ["SearchController": searchController.view]
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[SearchController]|", options: .AlignAllCenterY, metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[SearchController]|", options: .AlignAllCenterX, metrics: nil, views: views))
        
        if animated {
            searchController.view.alpha = 0.5
            searchController.view.transform = CGAffineTransformMakeScale(0.94, 0.94)
            UIView.animateWithDuration(0.15, delay: 0.0, options: .CurveEaseOut, animations: { () -> Void in
                searchController.view.alpha = 1.0
                searchController.view.transform = CGAffineTransformIdentity
            }) { (completed) -> Void in
                searchController.didMoveToParentViewController(self)
            }
        } else {
            searchController.view.alpha = 1.0
            searchController.view.transform = CGAffineTransformIdentity
            searchController.didMoveToParentViewController(self)
        }
    }
    
    private func hideSearchResultController(animated animated: Bool) {
        guard let searchController = childViewControllers.flatMap({$0 as? SearchController}).first else {return}
        let completion = { (complete: Bool) -> Void in
            searchController.view.removeFromSuperview()
            searchController.removeFromParentViewController()
            guard self.traitCollection.horizontalSizeClass == .Compact else {return}
            self.navigationController?.setToolbarHidden(false, animated: animated)
        }
        
        searchController.willMoveToParentViewController(nil)
        if animated {
            UIView.animateWithDuration(0.15, delay: 0.0, options: .BeginFromCurrentState, animations: { 
                searchController.view.alpha = 0.0
                searchController.view.transform = CGAffineTransformMakeScale(0.96, 0.96)
                }, completion: completion)
        } else {
            completion(true)
        }
    }
    
    // MARK: - Show/Hide TOC
    
    func animateInTableOfContentsController() {
        isShowingTableOfContents = true
        tocVisiualEffectView.hidden = false
        dimView.hidden = false
        dimView.alpha = 0.0
        view.layoutIfNeeded()
        tableOfContentsController?.headings = getTableOfContents(webView)
        configureTOCViewConstraints()
        UIView.animateWithDuration(0.3, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.0, options: .CurveEaseOut, animations: {
            self.view.layoutIfNeeded()
            self.dimView.alpha = 0.5
        }) { (completed) in
            
        }
    }
    
    func animateOutTableOfContentsController() {
        isShowingTableOfContents = false
        view.layoutIfNeeded()
        configureTOCViewConstraints()
        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseIn, animations: {
            self.view.layoutIfNeeded()
            self.dimView.alpha = 0.0
        }) { (completed) in
            self.dimView.hidden = true
            self.tocVisiualEffectView.hidden = true
        }
    }
    
    func configureTOCViewConstraints() {
        switch traitCollection.horizontalSizeClass {
        case .Compact:
            let tocHeight: CGFloat = {
                guard let controller = tableOfContentsController else {return floor(view.frame.height * 0.4)}
                let tocContentHeight = controller.tableView.contentSize.height
                guard controller.headings.count != 0 else {return floor(view.frame.height * 0.4)}
                let toolBarHeight: CGFloat = traitCollection.horizontalSizeClass == .Regular ? 0.0 : (traitCollection.verticalSizeClass == .Compact ? 32.0 : 44.0)
                return min(tocContentHeight + toolBarHeight, floor(view.frame.height * 0.65))
            }()
            tocHeightConstraint.constant = tocHeight
            tocTopToSuperViewBottomSpacing.constant = isShowingTableOfContents ? tocHeight : 0.0
        case .Regular:
            tocLeadSpacing.constant = isShowingTableOfContents ? 0.0 : 270
            break
        default:
            break
        }
    }
    
    // MARK: - Show Bookmark
    
    func showBookmarkTBVC() {
        guard let controller = bookmarkNav ?? UIStoryboard.main.initViewController("BookmarkNav", type: UINavigationController.self) else {return}
        bookmarkNav = controller
        controller.modalPresentationStyle = .FormSheet
        presentViewController(controller, animated: true, completion: nil)
    }
    
    // MARK: - Show/Hide Welcome
    
    func showWelcome() {
        guard let controller = welcomeController ?? UIStoryboard.welcome.instantiateInitialViewController() else {return}
        welcomeController = controller
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(controller)
        view.addSubview(controller.view)
        
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: NSLayoutFormatOptions.AlignAllTop, metrics: nil, views: ["view": controller.view]))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: NSLayoutFormatOptions.AlignAllLeft, metrics: nil, views: ["view": controller.view]))
        
        controller.didMoveToParentViewController(self)
    }
    
    func hideWelcome() {
        guard let controller = welcomeController else {return}
        controller.removeFromParentViewController()
        controller.view.removeFromSuperview()
    }
    
    // MARK: - Show/Hide Get Started
    
    func showGetStarted() {
        guard let controller = UIStoryboard.welcome.initViewController(GetStartedController.self) else {return}
        controller.modalPresentationStyle = .FormSheet
        presentViewController(controller, animated: true, completion: nil)
    }
    
    // MARK: - Show First Time Launch Alert
    
    func showGetStartedAlert() {
        guard !Preference.hasShowGetStartedAlert else {return}
        let operation = GetStartedAlert(mainController: self)
        GlobalOperationQueue.sharedInstance.addOperation(operation)
        Preference.hasShowGetStartedAlert = true
    }
}