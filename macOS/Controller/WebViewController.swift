//
//  WebViewController.swift
//  macOS
//
//  Created by Chris Li on 10/12/19.
//  Copyright © 2019 Chris Li. All rights reserved.
//

import Cocoa
import WebKit

class WebViewController: NSViewController, WKNavigationDelegate {
    private let webView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(KiwixURLSchemeHandler(), forURLScheme: "kiwix")
        config.mediaTypesRequiringUserActionForPlayback = []
        return WKWebView(frame: .zero, configuration: config)
    }()
    
    override func loadView() {
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        webView.navigationDelegate = self
    }
    
    func load(url: URL) {
        let request = URLRequest(url: url)
        webView.load(request)
        
    }
    
    func loadMainPage(id: ZimFileID) {
        
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        view.window?.title = webView.title ?? ""
    }
}
