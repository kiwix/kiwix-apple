//
//  WebViewDelegate.swift
//  Kiwix
//
//  Created by Chris Li on 9/9/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import SafariServices

class WebViewDelegate: NSObject, UIWebViewDelegate, SFSafariViewControllerDelegate {
    
    weak var delegate: MainController?
    
    // MARK: - UIWebViewDelegate
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        guard let url = request.URL else {return false}
        guard url.scheme?.caseInsensitiveCompare("kiwix") == .OrderedSame else {
            let svc = SFSafariViewController(URL: url)
            svc.delegate = self
            delegate?.presentViewController(svc, animated: true, completion: nil)
            return false
        }
        return true
    }
    
    func webViewDidStartLoad(webView: UIWebView) {
        
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        print(error)
    }
    
    // MARK: - SFSafariViewControllerDelegate
    
    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
}
