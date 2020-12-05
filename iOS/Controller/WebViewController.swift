//
//  WebViewController.swift
//  Kiwix
//
//  Created by Chris Li on 12/5/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import UIKit
import WebKit
import SafariServices
import Defaults

class WebViewController: UIViewController {
    let webView: WKWebView = {
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
        webView.allowsBackForwardNavigationGestures = true
        if #available(iOS 14.0, *) {
            navigationController?.isNavigationBarHidden = true
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        webView.setValue(view.safeAreaInsets, forKey: "_obscuredInsets")
    }
}
