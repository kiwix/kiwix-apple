//
//  MainVCOtherD.swift
//  Kiwix
//
//  Created by Chris Li on 1/22/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import SafariServices

extension MainVC: LPTBarButtonItemDelegate, TableOfContentsDelegate, UISearchBarDelegate, UIPopoverPresentationControllerDelegate, UIWebViewDelegate, SFSafariViewControllerDelegate, UIScrollViewDelegate {
    
    // MARK: - LPTBarButtonItemDelegate
    
    func barButtonTapped(sender: LPTBarButtonItem, gestureRecognizer: UIGestureRecognizer) {
        guard sender == bookmarkButton else {return}
        
        guard let controller = bookmarkController ?? UIStoryboard.main.initViewController("BookmarkNav", type: UINavigationController.self) else {return}
        bookmarkController = controller
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
    
    // MARK: - TableOfContentsDelegate
    
    func scrollTo(heading: HTMLHeading) {
        webView.stringByEvaluatingJavaScriptFromString(heading.scrollToJavaScript)
        if traitCollection.horizontalSizeClass == .Compact {
            animateOutTableOfContentsController()
        }
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
        searchController?.searchText = searchText
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchController?.searchResultTBVC?.selectFirstResultIfPossible()
    }
    
    // MARK: -  UIPopoverPresentationControllerDelegate
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .None
    }
    
    // MARK: - UIWebViewDelegate
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        guard let url = request.URL else {return true}
        if url.scheme == "kiwix" {
            return true
        } else {
            let svc = SFSafariViewController(URL: url)
            svc.delegate = self
            presentViewController(svc, animated: true, completion: nil)
            return false
        }
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        guard let url = webView.request?.URL else {return}
        guard url.scheme.caseInsensitiveCompare("Kiwix") == .OrderedSame else {return}
        
        let title = webView.stringByEvaluatingJavaScriptFromString("document.title")
        let managedObjectContext = UIApplication.appDelegate.managedObjectContext
        guard let bookID = url.host else {return}
        guard let book = Book.fetch(bookID, context: managedObjectContext) else {return}
        guard let article = Article.addOrUpdate(title, url: url, book: book, context: managedObjectContext) else {return}
        
        self.article = article
        configureSearchBarPlaceHolder()
        injectTableWrappingJavaScriptIfNeeded()
        adjustFontSizeIfNeeded()
        configureNavigationButtonTint()
        configureBookmarkButton()
        
        if traitCollection.horizontalSizeClass == .Regular && isShowingTableOfContents {
            tableOfContentsController?.headings = getTableOfContents(webView)
        }
    }
    
    func injectTableWrappingJavaScriptIfNeeded() {
        if Preference.webViewInjectJavascriptToAdjustPageLayout {
            if traitCollection.horizontalSizeClass == .Compact {
                guard let path = NSBundle.mainBundle().pathForResource("adjustlayoutiPhone", ofType: "js") else {return}
                guard let jString = Utilities.contentOfFileAtPath(path) else {return}
                webView.stringByEvaluatingJavaScriptFromString(jString)
            } else {
                guard let path = NSBundle.mainBundle().pathForResource("adjustlayoutiPad", ofType: "js") else {return}
                guard let jString = Utilities.contentOfFileAtPath(path) else {return}
                webView.stringByEvaluatingJavaScriptFromString(jString)
            }
        }
    }
    
    func adjustFontSizeIfNeeded() {
        let zoomScale = Preference.webViewZoomScale
        guard zoomScale != 100.0 else {return}
        let jString = String(format: "document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '%.0f%%'", zoomScale)
        webView.stringByEvaluatingJavaScriptFromString(jString)
    }
    
    // MARK: - UIPopoverPresentationControllerDelegate
    
    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        guard scrollView.contentSize.height >= scrollView.frame.height else {return}
        guard let navigationBar = navigationController?.navigationBar else {return}
        guard scrollView.contentOffset.y > 100 else {return}
        
        // Calculate current YOffset but without elasticity
        let currentScrollViewYOffset: CGFloat = {
            let topInset = scrollView.contentInset.top
            let bottomInset = scrollView.contentInset.bottom
            let minYOffset = -topInset
            let maxYOffset = scrollView.contentSize.height + bottomInset - scrollView.frame.height
            return max(minYOffset, min(scrollView.contentOffset.y, maxYOffset))
        }()
        
        // delta content offset y, scroll up minus, scroll down plus
        let yDelta = previousScrollViewYOffset - currentScrollViewYOffset
        
        // Slide up nav bar
        let navOriginY = max(20.0 - 44.0, min(navigationBar.frame.origin.y + yDelta, 20.0))
        let navFrame = CGRectMake(0, navOriginY, navigationBar.frame.width, navigationBar.frame.height)
        navigationBar.frame = navFrame
        
        // Slide down tool bar
        if let toolBar = navigationController?.toolbar {
            let originY = max(view.frame.height - 44.0, min(toolBar.frame.origin.y - yDelta, view.frame.height))
            let frame = CGRectMake(0, originY, toolBar.frame.width, toolBar.frame.height)
            toolBar.frame = frame
        }
        
        // Shrink nav bar
        //let newNavBarHeight = max(navBarMinHeight, min(navigationBar.frame.height + yDelta, 44.0))
        //let navFrame = CGRectMake(0, navigationBar.frame.origin.y, navigationBar.frame.width, newNavBarHeight)
        //navigationBar.frame = navFrame
        
        updateNavBarItems()
        configureWebViewInsets()
        previousScrollViewYOffset = currentScrollViewYOffset
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        stoppedScrolling()
    }
    
    func updateNavBarItems() {
        guard let navigationBar = navigationController?.navigationBar else {return}
        let min: CGFloat = 20.0 - 44.0
        let max: CGFloat = 20.0
        let alpha = (navigationBar.frame.origin.y - min) / (max - min)
        navigationItem.titleView?.alpha = alpha
    }
    
    func stoppedScrolling() {
        guard let navigationBar = navigationController?.navigationBar else {return}
        let show = ((navigationBar.frame.origin.y - (20-44)) / 44) > 0.5
        animateBar(show)
    }
    
    func animateBar(show: Bool) {
        UIView.animateWithDuration(0.2) { () -> Void in
            if show {
                if let navBar = self.navigationController?.navigationBar {
                    navBar.frame = CGRectMake(0, 20, navBar.frame.width, navBar.frame.height)
                }
                if let toolBar = self.navigationController?.toolbar {
                    toolBar.frame = CGRectMake(0, self.view.frame.height - toolBar.frame.height, toolBar.frame.width, toolBar.frame.height)
                }
                self.navigationItem.titleView?.alpha = 1.0
            } else {
                if let navBar = self.navigationController?.navigationBar {
                    navBar.frame = CGRectMake(0, 20 - 44, navBar.frame.width, navBar.frame.height)
                }
                if let toolBar = self.navigationController?.toolbar {
                    toolBar.frame = CGRectMake(0, self.view.frame.height, toolBar.frame.width, toolBar.frame.height)
                }
                self.navigationItem.titleView?.alpha = 0.0
            }
        }
    }
    
}