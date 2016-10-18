//
//  MainControllerOtherD.swift
//  Kiwix
//
//  Created by Chris Li on 1/22/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import CoreData
import SafariServices
import JavaScriptCore
import DZNEmptyDataSet

extension MainController: UIWebViewDelegate, SFSafariViewControllerDelegate, LPTBarButtonItemDelegate, UIViewControllerTransitioningDelegate, TableOfContentsDelegate, ZimMultiReaderDelegate, UISearchBarDelegate, UIPopoverPresentationControllerDelegate {
    
    // MARK: - UIWebViewDelegate
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        guard let url = request.URL else {return false}
        guard url.scheme?.caseInsensitiveCompare("pagescroll") != .OrderedSame else {
            let components = NSURLComponents(string: url.absoluteString!)
            let ids = components?.queryItems?.filter({$0.name == "header"}).flatMap({$0.value}) ?? [String]()
            tableOfContentsController?.visibleHeaderIDs = ids
            return false
        }
        guard url.isKiwixURL else {
            let controller = SFSafariViewController(URL: url)
            controller.delegate = self
            presentViewController(controller, animated: true, completion: nil)
            return false
        }
        return true
    }
    
    func webViewDidStartLoad(webView: UIWebView) {
        URLResponseCache.shared.start()
        
        // UI Updates
        if webView.hidden {
            webView.hidden = false
            hideWelcome()
        }
        hideSearch(animated: true)
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        URLResponseCache.shared.stop()
        
        // Create article object
        guard let url = webView.request?.URL,
            let article = Article.addOrUpdate(url: url, context: NSManagedObjectContext.mainQueueContext) else {return}
        article.title = JS.getTitle(from: webView)
        article.thumbImagePath = URLResponseCache.shared.firstImage()?.path
        self.article = article
        
        // JS
        JS.inject(webView)
        JS.adjustFontSizeIfNeeded(webView)
        if isShowingTableOfContents {
            configureTableOfContents()
            JS.startTOCCallBack(webView)
        }
        
        // UI Updates
        configureNavigationButtonTint()
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
        showBookmarkController()
    }
    
    func barButtonLongPressedStart(sender: LPTBarButtonItem, gestureRecognizer: UIGestureRecognizer) {
        guard sender == bookmarkButton else {return}
        guard !webView.hidden else {return}
        guard let article = article else {return}
        
        article.isBookmarked = !article.isBookmarked
        if article.isBookmarked {article.bookmarkDate = NSDate()}
        if article.snippet == nil {article.snippet = JS.getSnippet(webView)}
        
//        let cloudKitUpdateOperation = BookmarkCloudKitOperation(article: article)
//        GlobalQueue.shared.addOperation(cloudKitUpdateOperation)
        
        let updateWidgetOperation = UpdateWidgetDataSourceOperation()
        GlobalQueue.shared.addOperation(updateWidgetOperation)
        
        let controller = Controllers.bookmarkHUD
        controller.bookmarkAdded = article.isBookmarked
        controller.transitioningDelegate = self
        controller.modalPresentationStyle = .OverFullScreen
        presentViewController(controller, animated: true, completion: nil)
        configureBookmarkButton()
    }
    
    // MARK: - UIViewControllerTransitioningDelegate
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BookmarkHUDAnimator(animateIn: true)
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BookmarkHUDAnimator(animateIn: false)
    }
    
    // MARK: - TableOfContentsDelegate
    
    func scrollTo(heading: HTMLHeading) {
        webView.stringByEvaluatingJavaScriptFromString(heading.scrollToJavaScript)
        if traitCollection.horizontalSizeClass == .Compact {
            hideTableOfContentsController()
        }
    }
    
    // MARK: - ZimMultiReaderDelegate
    
    func firstBookAdded() {
        guard let bookID = ZimMultiReader.shared.readers.keys.first else {return}
        let operation = ArticleLoadOperation(bookID: bookID)
        GlobalQueue.shared.add(load: operation)
    }
    
    // MARK: -  UIPopoverPresentationControllerDelegate
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .None
    }
    
}
