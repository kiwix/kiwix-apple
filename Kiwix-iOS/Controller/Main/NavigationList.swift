//
//  NavigationStack.swift
//  Kiwix
//
//  Created by Chris Li on 11/20/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit

class NavigationList {
    var backList = [URL]()
    var forwardList = [URL]()
    var currentURL: URL?
    
    func webViewStartLoading(requestURL: URL) {
        guard let currentURL = currentURL else {
            self.currentURL = requestURL
            return
        }
        
        guard currentURL != requestURL else {return}
        backList.append(currentURL)
        self.currentURL = requestURL
        forwardList.removeAll()
    }
    
    func goBack(webView: UIWebView) {
        guard let lastURL = backList.last, let currentURL = currentURL else {return}
        backList.removeLast()
        self.currentURL = lastURL
        forwardList.insert(currentURL, at: 0)
        
        let request = URLRequest(url: lastURL)
        webView.loadRequest(request)
    }
    
    func goForward(webView: UIWebView) {
        guard let nextURL = forwardList.first, let currentURL = currentURL else {return}
        backList.append(currentURL)
        self.currentURL = nextURL
        forwardList.removeFirst()
        
        let request = URLRequest(url: nextURL)
        webView.loadRequest(request)
    }
    
    var canGoBack: Bool {
        return backList.count > 0
    }
    
    var canGoForward: Bool {
        return forwardList.count > 0
    }

}
