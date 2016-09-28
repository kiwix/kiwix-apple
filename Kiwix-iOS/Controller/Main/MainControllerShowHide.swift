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
    
    func showSearch(animated animated: Bool) {
        // Hide any presenting controller
        presentedViewController?.dismissViewControllerAnimated(animated, completion: nil)
        
        // Hide TOC
        if isShowingTableOfContents && traitCollection.horizontalSizeClass == .Compact {
            hideTableOfContentsController()
        }
        
        // Hide ToolBar &
        navigationController?.setToolbarHidden(true, animated: animated)
        
        // Show Search Result Controller
        showSearchResultController(animated: animated)
        
        // SearchBar
        searchBar.placeholder = LocalizedStrings.search
        if !searchBar.isFirstResponder() {searchBar.becomeFirstResponder()}
        
        // Show Cancel Button If Needed
        if traitCollection.horizontalSizeClass == .Compact {
            if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
                navigationItem.setRightBarButtonItem(cancelButton, animated: animated)
            } else if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
                searchBar.setShowsCancelButton(true, animated: animated)
            }
        }
    }
    
    func hideSearch(animated animated: Bool) {
        // Hide Search Result Controller
        hideSearchResultController(animated: true)
        
        // Search Bar
        searchBar.text = nil
        if searchBar.isFirstResponder() {searchBar.resignFirstResponder()}
        
        // Hide Cancel Button If Needed
        if traitCollection.horizontalSizeClass == .Compact {
            if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
                navigationItem.setRightBarButtonItem(nil, animated: animated)
            } else if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
                searchBar.setShowsCancelButton(false, animated: animated)
            }
        }
    }
    
    private func showSearchResultController(animated animated: Bool) {
        let controller = Controllers.search
        guard !childViewControllers.contains(controller) else {return}
        addChildViewController(controller)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controller.view)
        
        let views = ["SearchController": controller.view]
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[SearchController]|", options: .AlignAllCenterY, metrics: nil, views: views))
        
        view.addConstraint(controller.view.topAnchor.constraintEqualToAnchor(topLayoutGuide.bottomAnchor))
        view.addConstraint(controller.view.bottomAnchor.constraintEqualToAnchor(bottomLayoutGuide.topAnchor))
        
        if animated {
            controller.view.alpha = 0.5
            controller.view.transform = CGAffineTransformMakeScale(0.94, 0.94)
            UIView.animateWithDuration(0.15, delay: 0.0, options: .CurveEaseOut, animations: { () -> Void in
                controller.view.alpha = 1.0
                controller.view.transform = CGAffineTransformIdentity
            }, completion: nil)
        } else {
            controller.view.alpha = 1.0
            controller.view.transform = CGAffineTransformIdentity
        }
        controller.didMoveToParentViewController(self)
    }
    
    private func hideSearchResultController(animated animated: Bool) {
        guard let searchController = childViewControllers.flatMap({$0 as? SearchController}).first else {return}
        let completion = { (complete: Bool) -> Void in
            guard complete else {return}
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
    
    func showTableOfContentsController() {
        isShowingTableOfContents = true
        tocVisiualEffectView.hidden = false
        dimView.hidden = false
        dimView.alpha = 0.0
        view.layoutIfNeeded()
        tableOfContentsController?.headings = JSInjection.getTableOfContents(webView)
        configureTOCViewConstraints()
        UIView.animateWithDuration(0.3, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.0, options: .CurveEaseOut, animations: {
            self.view.layoutIfNeeded()
            self.dimView.alpha = 0.5
        }) { (completed) in
            
        }
    }
    
    func hideTableOfContentsController() {
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
        let controller = Controllers.bookmark
        controller.modalPresentationStyle = .FormSheet
        presentViewController(controller, animated: true, completion: nil)
    }
    
    // MARK: - Show/Hide Welcome
    
    func showWelcome() {
        let controller = Controllers.welcome
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(controller)
        view.addSubview(controller.view)
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: NSLayoutFormatOptions.AlignAllTop, metrics: nil, views: ["view": controller.view]))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: NSLayoutFormatOptions.AlignAllLeft, metrics: nil, views: ["view": controller.view]))
        controller.didMoveToParentViewController(self)
    }
    
    func hideWelcome() {
        guard let controller = childViewControllers.flatMap({$0 as? WelcomeController}).first else {return}
        controller.removeFromParentViewController()
        controller.view.removeFromSuperview()
    }
    
    // MARK: - Show First Time Launch Alert
    
    func showGetStartedAlert() {
        guard !Preference.hasShowGetStartedAlert else {return}
        let operation = GetStartedAlert(context: self)
        GlobalQueue.shared.addOperation(operation)
    }
}
