//
//  MainVCD.swift
//  Kiwix
//
//  Created by Chris on 12/30/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit

extension MainVC: UISearchControllerDelegate, WebViewLoadingDelegate, UISearchBarDelegate, LPTBarButtonItemDelegate {
    
    // MARK: - UISearchControllerDelegate
    
    func willPresentSearchController(searchController: UISearchController) {
        self.dismissViewControllerAnimated(true, completion: nil)
        switch traitCollection.horizontalSizeClass {
        case .Compact:
            if UIDevice.currentDevice().userInterfaceIdiom == .Pad {navigationItem.rightBarButtonItem = cancelButton}
        case .Regular:
            searchController.preferredContentSize = CGSizeMake(searchController.searchBar.frame.width, self.view.frame.size.height * 0.75)
            searchController.popoverPresentationController?.permittedArrowDirections = .Up
            searchController.dimsBackgroundDuringPresentation = true
        case .Unspecified:
            break
        }
        searchController.searchBar.placeholder = searchBarOriginalPlaceHolder
    }
    
    func didPresentSearchController(searchController: UISearchController) {
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            self.navigationController?.toolbarHidden = true
            searchController.searchBar.becomeFirstResponder()
        }
    }
    
    func willDismissSearchController(searchController: UISearchController) {
        navigationController?.toolbarHidden = false
        if self.traitCollection.horizontalSizeClass == .Compact {
            self.navigationItem.rightBarButtonItem = nil
        }
        let fittedArticleTitle = Utilities.truncatedPlaceHolderString(article?.title, searchBar: searchController.searchBar)
        searchController.searchBar.placeholder = fittedArticleTitle ?? searchBarOriginalPlaceHolder
    }
    
    // MARK: - WebViewLoadingDelegate
    
    func webViewDidFinishLoad(article: Article?, canGoback: Bool, canGoForward: Bool) {
        self.article = article
        searchController.searchBar.placeholder = {
            if let title = article?.title {
                return Utilities.truncatedPlaceHolderString(title, searchBar: searchController.searchBar)
            } else {
                return searchBarOriginalPlaceHolder
            }
        }()
        navigateLeftButton.tintColor = canGoback ? nil : UIColor.lightGrayColor()
        navigateRightButton.tintColor = canGoForward ? nil : UIColor.lightGrayColor()
        configureBookmarkButton()
    }
    
    // MARK: - LPTBarButtonItemDelegate
    
    func barButtonTapped(sender: LPTBarButtonItem, gestureRecognizer: UIGestureRecognizer) {
        guard sender == bookmarkButton else {return}
        
        guard let controller = bookmarkVC ?? UIStoryboard.main.initViewController("BookmarkNav", type: UINavigationController.self) else {return}
        bookmarkVC = controller
        controller.modalPresentationStyle = .FormSheet
        presentViewController(controller, animated: true, completion: nil)
    }
    
    func barButtonLongPressedStart(sender: LPTBarButtonItem, gestureRecognizer: UIGestureRecognizer) {
        guard sender == bookmarkButton else {return}
        
        guard !isShowingWelcome else {return}
        guard let article = article else {return}
        guard let bookmarkHUDVC = UIStoryboard.main.initViewController(BookmarkHUDVC.self) else {return}
        UIApplication.appDelegate.window?.addSubview(bookmarkHUDVC.view)
        article.isBookmarked = !article.isBookmarked
        bookmarkHUDVC.show(article.isBookmarked)
        configureBookmarkButton()
    }
}