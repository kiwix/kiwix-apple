//
//  LegacyTabViewViewController.swift
//  WikiMed
//
//  Created by Chris Li on 9/6/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import SafariServices

class LegacyTabController: TabController, UIWebViewDelegate, ToolBarControlEvents {
    let webView = UIWebView()
    let toolBarController = ToolBarController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addWebView()
        addToolBar()
        loadMainPage()
    }
    
    private func addWebView() {
        webView.delegate = self
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[webView]|", options: [], metrics: nil, views: ["webView": webView]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[webView]|", options: [], metrics: nil, views: ["webView": webView]))
    }
    
    private func addToolBar() {
        toolBarController.delegate = self
        addChildViewController(toolBarController)
        let toolBar = toolBarController.view!
        toolBar.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(toolBar, aboveSubview: webView)
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[toolBar]-(10)-|", options: [], metrics: nil, views: ["toolBar": toolBar]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[toolBar]-(10)-|", options: [], metrics: nil, views: ["toolBar": toolBar]))
        toolBarController.didMove(toParentViewController: self)
    }
    
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
