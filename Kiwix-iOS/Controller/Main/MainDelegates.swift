//
//  MainControllerDelegates.swift
//  Kiwix
//
//  Created by Chris Li on 11/14/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit
import SafariServices

// MARK: - Web

extension MainController: UIWebViewDelegate, SFSafariViewControllerDelegate {
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        guard let url = request.url else {return false}
        guard url.isKiwixURL else {
            let controller = SFSafariViewController(url: url)
            controller.delegate = self
            present(controller, animated: true, completion: nil)
            return false
        }
        return true
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        URLResponseCache.shared.start()
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        JS.preventDefaultLongTap(webView: webView)
        URLResponseCache.shared.stop()
        
        buttons.back.tintColor = webView.canGoBack ? nil : UIColor.gray
        buttons.forward.tintColor = webView.canGoForward ? nil : UIColor.gray
        
        guard let title = JS.getTitle(from: webView) else {return}
        searchBar.title = title
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
    }
}

// MARK: - Search

extension MainController: SearchBarDelegate, SearchContainerDelegate {
    
    func didBecomeFirstResponder(searchBar: SearchBar) {
        showSearch(animated: true)
    }
    
    func didResignFirstResponder(searchBar: SearchBar) {
        hideSearch(animated: true)
    }
    
    func textDidChange(text: String, searchBar: SearchBar) {
        controllers.search.searchText = text
    }
    
    private func showSearch(animated: Bool) {
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
        
        let views = ["view": controller.view]
        view.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "H:|[view]|", options: .alignAllCenterY, metrics: nil, views: views))
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
    
    private func hideSearch(animated: Bool) {
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
    
    func didTapSearchDimView() {
        _ = searchBar.resignFirstResponder()
    }
}

// MARK: - Button Delegates

extension MainController: ButtonDelegates {
    func didTapBackButton() {
        webView.goBack()
    }
    
    func didTapForwardButton() {
        webView.goForward()
    }
    
    func didTapTOCButton() {
        isShowingTableOfContents ? hideTableOfContents(animated: true) : showTableOfContents(animated: true)
    }
    
    func didTapBookmarkButton() {
        showBookmarkController()
    }
    
    func didTapLibraryButton() {
        present(controllers.library, animated: true, completion: nil)
    }
    
    func didTapCancelButton() {
        _ = searchBar.resignFirstResponder()
    }
    
    func didLongPressBackButton() {
    }
    
    func didLongPressForwardButton() {
    }
    
    func didLongPressBookmarkButton() {
        showBookmarkHUD()
        
//        guard let url
//        let article = Article.fetch(url: <#T##URL#>, context: <#T##NSManagedObjectContext#>)
    }
}

// MARK: - Table Of Content

extension MainController: TableOfContentsDelegate {
    func showTableOfContents(animated: Bool) {
        guard welcomeController == nil else {return}
        isShowingTableOfContents = true
        tocVisiualEffectView.isHidden = false
        dimView.isHidden = false
        dimView.alpha = 0.0
        view.layoutIfNeeded()
        
        //configureTableOfContents()
        configureTOCConstraints()
        
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.0, options: .curveEaseOut, animations: {
                self.view.layoutIfNeeded()
                self.dimView.alpha = 0.5
            }) { (completed) in }
        } else {
            view.layoutIfNeeded()
            dimView.alpha = 0.5
        }
        
        JS.startTOCCallBack(webView)
    }
    
    func hideTableOfContents(animated: Bool) {
        isShowingTableOfContents = false
        view.layoutIfNeeded()
        
        configureTOCConstraints()
        if animated {
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseIn, animations: {
                self.view.layoutIfNeeded()
                self.dimView.alpha = 0.0
            }) { (completed) in
                self.dimView.isHidden = true
                self.tocVisiualEffectView.isHidden = true
            }
        } else {
            view.layoutIfNeeded()
            dimView.alpha = 0.0
            dimView.isHidden = true
            tocVisiualEffectView.isHidden = true
        }
        
        JS.stopTOCCallBack(webView)
    }
    
    func configureTOCConstraints() {
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
        default:
            break
        }
    }
    
    func didSelectTOCItem(heading: HTMLHeading) {
        
    }
    
    @IBAction func didTapTOCDimView(_ sender: UITapGestureRecognizer) {
        hideTableOfContents(animated: true)
    }
}

// MARK: - Welcome

extension MainController {
    func showWelcome() {
        let controller = controllers.welcome
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(controller)
        view.insertSubview(controller.view, aboveSubview: webView)
        let views = ["view": controller.view]
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: .alignAllTop, metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: .alignAllLeft, metrics: nil, views: views))
        controller.didMove(toParentViewController: self)
    }
    
    func hideWelcome() {
        guard let controller = welcomeController else {return}
        controller.removeFromParentViewController()
        controller.view.removeFromSuperview()
    }
    
    var welcomeController: WelcomeController? {
        return childViewControllers.flatMap({$0 as? WelcomeController}).first
    }
}

// MARK: - Bookmark

extension MainController: UIViewControllerTransitioningDelegate {
    func showBookmarkController() {
//        let controller = Controllers.bookmark
//        controller.modalPresentationStyle = .formSheet
//        present(controller, animated: true, completion: nil)
    }
    
    func showBookmarkHUD() {
        let controller = controllers.bookmarkHUD
        controller.bookmarkAdded = !controller.bookmarkAdded
        controller.transitioningDelegate = self
        controller.modalPresentationStyle = .overFullScreen
        present(controller, animated: true, completion: nil)
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BookmarkHUDAnimator(animateIn: true)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BookmarkHUDAnimator(animateIn: false)
    }
}

// MARK: - SFSafariViewControllerDelegate

extension MainController {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}
