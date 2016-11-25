//
//  MainControllerDelegates.swift
//  Kiwix
//
//  Created by Chris Li on 11/14/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit
import SafariServices

// MARK: - Search

extension MainController: SearchBarDelegate {
    
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
}

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
        controllers.navigationList.startLoading(requestURL: url)
        return true
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        JS.preventDefaultLongTap(webView: webView)
        guard let title = JS.getTitle(from: webView) else {return}
        searchBar.title = title
        
        buttons.back.tintColor = controllers.navigationList.canGoBack ? nil : UIColor.gray
        buttons.forward.tintColor = controllers.navigationList.canGoForward ? nil : UIColor.gray
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        
    }
}

// MARK: - SFSafariViewControllerDelegate

extension MainController {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Button Delegates

extension MainController: ButtonDelegates, SearchContainerDelegate {
    func didTapBackButton() {
//        navigationList.goBack(webView: webView)
    }
    
    func didTapForwardButton() {
//        navigationList.goForward(webView: webView)
    }
    
    func didTapTOCButton() {
        
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
        let controller = controllers.navigationList
        controller.type = .back
        controller.delegate = self
        let nav = UINavigationController(rootViewController: controller)
        present(nav, animated: true, completion: nil)
    }
    
    func didLongPressForwardButton() {
        let controller = controllers.navigationList
        controller.type = .forward
        controller.delegate = self
        let nav = UINavigationController(rootViewController: controller)
        present(nav, animated: true, completion: nil)
    }
    
    func didLongPressBookmarkButton() {
        showBookmarkHUD()
    }
}

// MARK: - NavigationListControllerDelegate

extension MainController: NavigationListControllerDelegate {
    func load(url: URL) {
        let request = URLRequest(url: url)
        webView.loadRequest(request)
    }
}

// MARK: - SearchContainerDelegate

extension MainController {
    func didTapDimView() {
        _ = searchBar.resignFirstResponder()
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
        guard let controller = childViewControllers.flatMap({$0 as? WelcomeController}).first else {return}
        controller.removeFromParentViewController()
        controller.view.removeFromSuperview()
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
