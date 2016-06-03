//
//  MainVCOtherD.swift
//  Kiwix
//
//  Created by Chris Li on 1/22/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

extension MainVC: LPTBarButtonItemDelegate, UISearchBarDelegate {
    
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
        guard !webView.hidden else {return}
        guard let article = article else {return}
        guard let bookmarkHUDVC = UIStoryboard.main.initViewController(BookmarkHUDVC.self) else {return}
        UIApplication.appDelegate.window?.addSubview(bookmarkHUDVC.view)
        article.isBookmarked = !article.isBookmarked
        bookmarkHUDVC.show(article.isBookmarked)
        configureBookmarkButton()
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        showSearch()
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        hideSearch()
        configureSearchBarPlaceHolder()
    }

    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        searchVC?.searchText = searchText
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchVC?.searchResultTBVC?.selectFirstResultIfPossible()
    }
}