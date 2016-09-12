//
//  MainControllerOtherD.swift
//  Kiwix
//
//  Created by Chris Li on 1/22/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import SafariServices
import JavaScriptCore
import DZNEmptyDataSet

extension MainController: UIWebViewDelegate, SFSafariViewControllerDelegate,
    LPTBarButtonItemDelegate, TableOfContentsDelegate, ZimMultiReaderDelegate, UISearchBarDelegate, UIPopoverPresentationControllerDelegate, UIScrollViewDelegate, UIViewControllerTransitioningDelegate {
    
    // MARK: - UIWebViewDelegate
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        guard let url = request.URL else {return false}
        guard url.isKiwixURL else {loadExternalResource(url); return false}
        return true
    }
    
    func webViewDidStartLoad(webView: UIWebView) {
        URLResponseCache.shared.start()
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        URLResponseCache.shared.stop()
        
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        // handle error
        print(error)
        
        article = nil
        URLResponseCache.shared.stop()
    }
    
    // MARK: - SFSafariViewControllerDelegate
    
    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - LPTBarButtonItemDelegate
    
    func barButtonTapped(sender: LPTBarButtonItem, gestureRecognizer: UIGestureRecognizer) {
        guard sender == bookmarkButton else {return}
        showBookmarkTBVC()
    }
    
    func barButtonLongPressedStart(sender: LPTBarButtonItem, gestureRecognizer: UIGestureRecognizer) {
        guard sender == bookmarkButton else {return}
        guard !webView.hidden else {return}
        guard let article = article else {return}
        
        article.isBookmarked = !article.isBookmarked
        if article.isBookmarked {article.bookmarkDate = NSDate()}
        if article.snippet == nil {article.snippet = JSInjection.getSnippet(webView)}
        
        let operation = UpdateWidgetDataSourceOperation()
        GlobalQueue.shared.addOperation(operation)
        
        let controller = ControllerRetainer.bookmarkStar
        controller.bookmarkAdded = article.isBookmarked
        controller.transitioningDelegate = self
        controller.modalPresentationStyle = .OverFullScreen
        presentViewController(controller, animated: true, completion: nil)
        configureBookmarkButton()
    }
    
    // MARK: - UIViewControllerTransitioningDelegate
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BookmarkControllerAnimator(animateIn: true)
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BookmarkControllerAnimator(animateIn: false)
    }
    
    // MARK: - TableOfContentsDelegate
    
    func scrollTo(heading: HTMLHeading) {
        webView.stringByEvaluatingJavaScriptFromString(heading.scrollToJavaScript)
        if traitCollection.horizontalSizeClass == .Compact {
            animateOutTableOfContentsController()
        }
    }
    
    // MARK: - ZimMultiReaderDelegate
    
    func firstBookAdded() {
        guard let id = ZimMultiReader.sharedInstance.readers.keys.first else {return}
        loadMainPage(id)
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        showSearch(animated: true)
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        hideSearch(animated: true)
        configureSearchBarPlaceHolder()
    }

    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        ControllerRetainer.search.startSearch(searchText, delayed: true)
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        ControllerRetainer.search.searchResultTBVC?.selectFirstResultIfPossible()
    }
    
    // MARK: -  UIPopoverPresentationControllerDelegate
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .None
    }
    
//    
//    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
//        guard let url = request.URL else {return true}
//        if url.scheme == "kiwix" {
//            return true
//        } else {
//            let svc = SFSafariViewController(URL: url)
//            svc.delegate = self
//            presentViewController(svc, animated: true, completion: nil)
//            return false
//        }
//    }
//    
//    func webViewDidStartLoad(webView: UIWebView) {
//        PacketAnalyzer.sharedInstance.startListening()
//    }
//    
//    func webViewDidFinishLoad(webView: UIWebView) {
//        guard let url = webView.request?.URL else {return}
//        guard url.scheme!.caseInsensitiveCompare("Kiwix") == .OrderedSame else {return}
//        
//        let title = webView.stringByEvaluatingJavaScriptFromString("document.title")
//        let managedObjectContext = UIApplication.appDelegate.managedObjectContext
//        guard let bookID = url.host else {return}
//        guard let book = Book.fetch(bookID, context: managedObjectContext) else {return}
//        guard let article = Article.addOrUpdate(title, url: url, book: book, context: managedObjectContext) else {return}
//        
//        self.article = article
//        if let image = PacketAnalyzer.sharedInstance.chooseImage() {
//            article.thumbImageURL = image.url.absoluteString
//        }
//        
//        configureSearchBarPlaceHolder()
//        injectTableWrappingJavaScriptIfNeeded()
//        adjustFontSizeIfNeeded()
//        configureNavigationButtonTint()
//        configureBookmarkButton()
//        

//        
//        PacketAnalyzer.sharedInstance.stopListening()
//    }
    
}
