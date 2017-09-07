//
//  LegacyTabViewViewController.swift
//  WikiMed
//
//  Created by Chris Li on 9/6/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class LegacyTabViewViewController: UIViewController, ToolBarControlEvents {
    let webView = UIWebView()
    let toolBarController = ToolBarController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addWebView()
        addToolBar()
        loadMainPage()
    }
    
    private func addWebView() {
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        view.addConstraint(NSLayoutConstraint(item: webView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: 0.0))
        view.addConstraint(NSLayoutConstraint(item: webView, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 0.0))
        view.addConstraint(NSLayoutConstraint(item: webView, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: 0.0))
        view.addConstraint(NSLayoutConstraint(item: webView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0.0))
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
