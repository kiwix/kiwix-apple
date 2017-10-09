//
//  LegacyTabViewViewController.swift
//  WikiMed
//
//  Created by Chris Li on 9/6/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import SafariServices

class LegacyTabController: UIViewController, UIWebViewDelegate, ToolBarControlEvents, ArticleLoading {
    let webView = UIWebView()
    let toolBarController = ToolBarController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureWebView()
        configureToolBar()
        updateToolBarButtons()
        loadMainPage()
    }
    
    private func configureWebView() {
        webView.delegate = self
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        webView.allowsLinkPreview = true
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        view.addConstraints([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leftAnchor.constraint(equalTo: view.leftAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.rightAnchor.constraint(equalTo: view.rightAnchor)])
    }
    
    private func configureToolBar() {
        toolBarController.delegate = self
        addChildViewController(toolBarController)
        let toolBar = toolBarController.view!
        toolBar.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(toolBar, aboveSubview: webView)
        if #available(iOS 11.0, *) {
            view.addConstraints([
                view.rightAnchor.constraint(equalTo: toolBar.rightAnchor, constant: 10),
                view.bottomAnchor.constraint(equalTo: toolBar.bottomAnchor, constant: 10)])
            additionalSafeAreaInsets = UIEdgeInsetsMake(0, 0, 100, 0)
        } else {
            view.addConstraints([
                view.rightAnchor.constraint(equalTo: toolBar.rightAnchor, constant: 10),
                view.bottomAnchor.constraint(equalTo: toolBar.bottomAnchor, constant: 10)])
        }
        
//        view.addConstraints([
//            view.rightAnchor.constraint(equalTo: toolBar.rightAnchor, constant: 10),
//            view.bottomAnchor.constraint(equalTo: toolBar.bottomAnchor, constant: 10)])
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
