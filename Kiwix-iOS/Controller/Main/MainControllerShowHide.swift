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
    
    func showSearch() {
        navigationController?.toolbarHidden = true
        animateInSearchResultController()
        searchBar.placeholder = LocalizedStrings.search
        if !searchBar.isFirstResponder() {
            searchBar.becomeFirstResponder()
        }
        if traitCollection.horizontalSizeClass == .Compact {
            searchBar.setShowsCancelButton(true, animated: true)
        }
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad && traitCollection.horizontalSizeClass == .Compact {
            navigationItem.setRightBarButtonItem(cancelButton, animated: true)
        }
        if isShowingTableOfContents && traitCollection.horizontalSizeClass == .Compact {
            animateOutTableOfContentsController()
        }
    }
    
    func hideSearch() {
        animateOutSearchResultController()
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.text = nil
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad && traitCollection.horizontalSizeClass == .Compact {
            navigationItem.setRightBarButtonItem(nil, animated: true)
        }
    }
    
    func animateInSearchResultController() {
        guard let searchController = searchController ?? UIStoryboard.search.instantiateInitialViewController() as? SearchController else {return}
        self.searchController = searchController
        guard !childViewControllers.contains(searchController) else {return}
        addChildViewController(searchController)
        searchController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchController.view)
        searchController.didMoveToParentViewController(self)
        searchController.view.alpha = 0.5
        searchController.view.transform = CGAffineTransformMakeScale(0.94, 0.94)
        
        let views = ["SearchController": searchController.view]
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[SearchController]|", options: .AlignAllCenterY, metrics: nil, views: views))
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[SearchController]|", options: .AlignAllCenterX, metrics: nil, views: views))
        
        UIView.animateWithDuration(0.15, delay: 0.0, options: .CurveEaseOut, animations: { () -> Void in
            searchController.view.alpha = 1.0
            searchController.view.transform = CGAffineTransformIdentity
            }, completion: nil)
    }
    
    func animateOutSearchResultController() {
        guard let searchResultVC = searchController else {return}
        UIView.animateWithDuration(0.15, delay: 0.0, options: .BeginFromCurrentState, animations: { () -> Void in
            searchResultVC.view.alpha = 0.0
            searchResultVC.view.transform = CGAffineTransformMakeScale(0.96, 0.96)
        }) { (completed) -> Void in
            searchResultVC.view.removeFromSuperview()
            searchResultVC.removeFromParentViewController()
            if self.traitCollection.horizontalSizeClass == .Compact {
                self.navigationController?.setToolbarHidden(false, animated: true)
            }
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