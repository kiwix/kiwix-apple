//
//  WebViewVC.swift
//  Kiwix
//
//  Created by Chris on 12/31/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit

class WebViewVC: UIViewController, UIWebViewDelegate {
    
    let managedObjectContext = UIApplication.appDelegate.managedObjectContext
    weak var delegate: WebViewLoadingDelegate?
    var context: UnsafeMutablePointer<Void> = nil
    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.delegate = self
        NSUserDefaults.standardUserDefaults().addObserver(self, forKeyPath: "webViewNotInjectJavascriptToAdjustPageLayout", options: .New, context: context)
        NSUserDefaults.standardUserDefaults().addObserver(self, forKeyPath: "webViewZoomScale", options: .New, context: context)
    }
    
    deinit {
        NSUserDefaults.standardUserDefaults().removeObserver(self, forKeyPath: "webViewNotInjectJavascriptToAdjustPageLayout")
        NSUserDefaults.standardUserDefaults().removeObserver(self, forKeyPath: "webViewZoomScale")
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard context == self.context else {return}
        webView.reload()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            webView.scrollView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0)
            webView.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(64, 0, 0, 0)
        } else {
            webView.scrollView.contentInset = UIEdgeInsetsMake(64, 0, 44, 0)
            webView.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(64, 0, 44, 0)
        }
        
    }
    
    func load(url: NSURL?) {
        guard let url = url else {return}
        let request = NSURLRequest(URL: url)
        webView.loadRequest(request)
    }
    
    func goBack() {
        webView.goBack()
    }
    
    func goForward() {
        webView.goForward()
    }
    
    // MARK: - UIWebViewDelegate
    
    func webViewDidFinishLoad(webView: UIWebView) {
        guard let _ = parentViewController as? MainVC else {return}
        guard let url = webView.request?.URL else {return}
        guard url.scheme.caseInsensitiveCompare("Kiwix") == .OrderedSame else {
            delegate?.webViewDidFinishLoad(nil, canGoback: webView.canGoBack, canGoForward: webView.canGoForward)
            return
        }
        
        let title = webView.stringByEvaluatingJavaScriptFromString("document.title")
        guard let bookID = url.host else {return}
        guard let book = Book.fetch(bookID, context: managedObjectContext) else {return}
        guard let article = Article.addOrUpdate(title, url: url, book: book, context: managedObjectContext) else {return}
        
        injectTableWrappingJavaScriptIfNeeded()
        adjustFontSizeIfNeeded()
        delegate?.webViewDidFinishLoad(article, canGoback: webView.canGoBack, canGoForward: webView.canGoForward)
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
    
}

protocol WebViewLoadingDelegate: class {
    func webViewDidFinishLoad(article: Article?, canGoback: Bool, canGoForward: Bool)
}