//
//  NavigationStack.swift
//  Kiwix
//
//  Created by Chris Li on 11/20/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit

class NavigationList {
    private var urls = [URL]()
    private var currentIndex: Int?
    
    var currentURL: URL? {
        guard let currentIndex = currentIndex else {return nil}
        return urls.indices.contains(currentIndex) ? urls[currentIndex] : nil
    }
    
    func webViewStartLoading(requestURL: URL) {
        guard currentURL != requestURL else {return}
        
        if let index = currentIndex {
            urls.removeLast(urls.count - index - 1)
            urls.append(requestURL)
            self.currentIndex = index + 1
        } else {
            urls.append(requestURL)
            self.currentIndex = 0
        }
    }
    
    func goBack(webView: UIWebView, backListIndex: Int = 0) {
        guard let currentIndex = currentIndex else {return}
        let index = currentIndex - 1 - backListIndex
        guard index >= 0 else {return}
        self.currentIndex = index
        
        guard let url = currentURL else {return}
        let request = URLRequest(url: url)
        webView.loadRequest(request)
    }
    
    func goForward(webView: UIWebView, forwardListIndex: Int = 0) {
        guard let currentIndex = currentIndex else {return}
        let index = currentIndex + 1 + forwardListIndex
        guard index <= urls.count - 1 else {return}
        self.currentIndex = index
        
        guard let url = currentURL else {return}
        let request = URLRequest(url: url)
        webView.loadRequest(request)
    }
    
    var backList: [URL] {
        guard let currentIndex = currentIndex else {return [URL]()}
        return Array(urls.prefix(currentIndex))
    }
    
    var forwardList: [URL] {
        guard let currentIndex = currentIndex else {return [URL]()}
        return Array(urls.suffix(urls.count - currentIndex - 1))
    }
    
    var canGoBack: Bool {
        guard let currentIndex = currentIndex else {return false}
        return currentIndex >= 1 && urls.indices.contains(currentIndex - 1)
    }
    
    var canGoForward: Bool {
        guard let currentIndex = currentIndex else {return false}
        return currentIndex >= 0 && urls.indices.contains(currentIndex + 1)
    }
}

