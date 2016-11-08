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
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        guard let url = request.url else {return false}
        guard url.scheme?.caseInsensitiveCompare("pagescroll") != .orderedSame else {
            let components = URLComponents(string: url.absoluteString)
            let ids = components?.queryItems?.filter({$0.name == "header"}).flatMap({$0.value}) ?? [String]()
            tableOfContentsController?.visibleHeaderIDs = ids
            return false
        }
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
        
        // UI Updates
        if webView.isHidden {
            webView.isHidden = false
            hideWelcome()
        }
        hideSearch(animated: true)
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        URLResponseCache.shared.stop()
        
        // Create article object
        guard let url = webView.request?.url,
            let article = Article.addOrUpdate(url: url, context: AppDelegate.persistentContainer.viewContext) else {return}
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
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        // handle error
        print(error)
        
        article = nil
        URLResponseCache.shared.stop()
    }
    
    // MARK: - SFSafariViewControllerDelegate
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - LPTBarButtonItemDelegate
    
    func barButtonTapped(_ sender: LPTBarButtonItem, gestureRecognizer: UIGestureRecognizer) {
        guard sender == bookmarkButton else {return}
        showBookmarkController()
    }
    
    func barButtonLongPressedStart(_ sender: LPTBarButtonItem, gestureRecognizer: UIGestureRecognizer) {
        guard sender == bookmarkButton else {return}
        guard !webView.isHidden else {return}
        guard let article = article else {return}
        
        article.isBookmarked = !article.isBookmarked
        if article.isBookmarked {article.bookmarkDate = Date()}
        if article.snippet == nil {article.snippet = JS.getSnippet(webView)}
        
//        let cloudKitUpdateOperation = BookmarkCloudKitOperation(article: article)
//        GlobalQueue.shared.addOperation(cloudKitUpdateOperation)
        
//        let updateWidgetOperation = UpdateWidgetDataSourceOperation()
//        GlobalQueue.shared.addOperation(updateWidgetOperation)
        
        let controller = Controllers.bookmarkHUD
        controller.bookmarkAdded = article.isBookmarked
        controller.transitioningDelegate = self
        controller.modalPresentationStyle = .overFullScreen
        present(controller, animated: true, completion: nil)
        configureBookmarkButton()
    }
    
    // MARK: - UIViewControllerTransitioningDelegate
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BookmarkHUDAnimator(animateIn: true)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BookmarkHUDAnimator(animateIn: false)
    }
    
    // MARK: - TableOfContentsDelegate
    
    func scrollTo(_ heading: HTMLHeading) {
        webView.stringByEvaluatingJavaScript(from: heading.scrollToJavaScript)
        if traitCollection.horizontalSizeClass == .compact {
            hideTableOfContentsController()
        }
    }
    
    // MARK: - ZimMultiReaderDelegate
    
    func firstBookAdded() {
        guard let bookID = ZimMultiReader.shared.readers.keys.first else {return}
//        let operation = ArticleLoadOperation(bookID: bookID)
//        GlobalQueue.shared.add(load: operation)
    }
    
    // MARK: -  UIPopoverPresentationControllerDelegate
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
}
