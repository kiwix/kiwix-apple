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
        article.title = JSInjection.getTitle(from: webView)
        article.thumbImageURL = URLResponseCache.shared.firstImage()?.absoluteString
        self.article = article
        
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
        if article.snippet == nil {article.snippet = JSInjection.getSnippet(webView)}
        
        let operation = UpdateWidgetDataSourceOperation()
        GlobalQueue.shared.addOperation(operation)
        
        let controller = Controllers.bookmarkStar
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
