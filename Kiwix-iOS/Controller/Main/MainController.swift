//
//  MainController.swift
//  Kiwix
//
//  Created by Chris Li on 11/13/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit

class MainController: UIViewController {
    
    @IBOutlet weak var webView: UIWebView!
    let searchBar = SearchBar()
    lazy var controllers = Controllers()
    lazy var buttons = Buttons()
    let navigationList = NavigationList()

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        webView.loadRequest(URLRequest(url: URL(string: "about:blank")!))
        navigationItem.titleView = searchBar
        searchBar.delegate = self
        buttons.delegate = self
        webView.delegate = self
        
        showWelcome()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        buttons.addLongTapGestureRecognizer()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass ||
            traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass else {return}
        switch traitCollection.horizontalSizeClass {
        case .compact:
            navigationController?.setToolbarHidden(false, animated: false)
            navigationItem.leftBarButtonItems = nil
            navigationItem.rightBarButtonItems = nil
            if searchBar.isFirstResponder {
                navigationItem.rightBarButtonItem = buttons.cancel
            }
            toolbarItems = buttons.toolbar
        case .regular:
            navigationController?.setToolbarHidden(true, animated: false)
            toolbarItems = nil
            navigationItem.leftBarButtonItems = buttons.navLeft
            navigationItem.rightBarButtonItems = buttons.navRight
        default:
            return
        }
    }
}

class WebView: UIWebView {
    var backList = [URL]()
    var forwardList = [URL]()
    var currentURL: URL?
    
    override var canGoBack: Bool {
        return backList.count > 0
    }
    
    override var canGoForward: Bool {
        return forwardList.count > 0
    }
    
    override func goBack() {
        guard let lastURL = backList.last, let currentURL = currentURL else {return}
        backList.removeLast()
        self.currentURL = lastURL
        forwardList.insert(currentURL, at: 0)
        
        let request = URLRequest(url: lastURL)
        loadRequest(request)
    }
    
    override func goForward() {
        guard let nextURL = forwardList.first, let currentURL = currentURL else {return}
        backList.append(currentURL)
        self.currentURL = nextURL
        forwardList.removeFirst()
        
        let request = URLRequest(url: nextURL)
        loadRequest(request)
    }
    
    override func loadRequest(_ request: URLRequest) {
        super.loadRequest(request)
        guard let currentURL = currentURL, let requestURL = request.url else {
            self.currentURL = request.url
            return
        }
        guard currentURL != requestURL else {return}
        backList.append(currentURL)
        self.currentURL = requestURL
        forwardList.removeAll()
    }
}
