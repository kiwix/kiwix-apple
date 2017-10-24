//
//  LegacyTabViewViewController.swift
//  WikiMed
//
//  Created by Chris Li on 9/6/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import SafariServices

class LegacyTabController: UIViewController, UIWebViewDelegate, TabController {
    private let webView = UIWebView()
    weak var delegate: TabLoadingActivity?
    
    override func loadView() {
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureWebView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        //        webView.scrollView.contentInset = UIEdgeInsetsMake(0, 0, toolBarController.view.frame.height + 20, 0)
    }
    
    var canGoBack: Bool {
        get {return webView.canGoBack}
    }
    
    var canGoForward: Bool {
        get {return webView.canGoForward}
    }
    
    // MARK: - Configure
    
    private func configureWebView() {
        webView.delegate = self
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        webView.allowsLinkPreview = true
        webView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    // MARK: - loading
    
    func goBack() {
        webView.goBack()
    }
    
    func goForward() {
        webView.goForward()
    }
    
    func loadMainPage() {
        guard let id = ZimMultiReader.shared.ids.first,
            let url = ZimMultiReader.shared.getMainPageURL(bookID: id) else {return}
        load(url: url)
    }
    
    func load(url: URL) {
        let request = URLRequest(url: url)
        webView.loadRequest(request)
    }
    
    // MARK: - UIWebViewDelegate
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        guard let url = request.url else {return false}
        if url.isKiwixURL {
            return true
        } else {
            let controller = SFSafariViewController(url: url)
            present(controller, animated: true, completion: nil)
            return false
        }
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        delegate?.loadingFinished()
    }
}
