//
//  WebKitTabController.swift
//  WikiMed
//
//  Created by Chris Li on 9/11/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import WebKit
import SafariServices

@available(iOS 11.0, *)
class WebKitTabController: UIViewController, WKUIDelegate, WKNavigationDelegate, ToolBarControlEvents {
    let webView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(KiwixURLSchemeHandler(), forURLScheme: "kiwix")
        return WKWebView(frame: CGRect.zero, configuration: config)
    }()
    let progressView = UIProgressView()
    let toolBarController = ToolBarController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureWebView()
//        configureProgressView()
        configureToolBar()
        updateToolBarButtons()
        loadMainPage()
    }
    
    private func configureWebView() {
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.allowsLinkPreview = true
        webView.allowsBackForwardNavigationGestures = true
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        view.addConstraints([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leftAnchor.constraint(equalTo: view.leftAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.rightAnchor.constraint(equalTo: view.rightAnchor)])
    }
    
    private func configureProgressView() {
        progressView.progressViewStyle = .bar
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(progressView, aboveSubview: webView)
        view.addConstraints([
            view.leftAnchor.constraint(equalTo: progressView.leftAnchor),
            view.rightAnchor.constraint(equalTo: progressView.rightAnchor)])
        view.addConstraint(view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: progressView.topAnchor))
    }
    
    private func configureToolBar() {
        toolBarController.delegate = self
        addChildViewController(toolBarController)
        let toolBar = toolBarController.view!
        toolBar.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(toolBar, aboveSubview: webView)
        view.addConstraints([
            view.rightAnchor.constraint(equalTo: toolBar.rightAnchor, constant: 10),
            view.bottomAnchor.constraint(equalTo: toolBar.bottomAnchor, constant: 10)])
        toolBarController.didMove(toParentViewController: self)
    }
    
    private func updateToolBarButtons() {
        toolBarController.back.tintColor = webView.canGoBack ? nil : UIColor.gray
        toolBarController.forward.tintColor = webView.canGoForward ? nil : UIColor.gray
    }
    
    // MARK: - loading
    
    func loadMainPage() {
        guard let id = ZimManager.shared.getReaderIDs().first,
            let url = ZimManager.shared.getMainPageURL(bookID: id) else {return}
        load(url: url)
    }
    
    func load(url: URL) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        updateToolBarButtons()
    }

    // MARK: - ToolBarControlEvents
    
    func backButtonTapped() {
        webView.goBack()
    }
    
    func forwardButtonTapped() {
        webView.goForward()
    }
    
    func homeButtonTapped() {
        loadMainPage()
    }

}
