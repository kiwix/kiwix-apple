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

class WebViewController: UIViewController, WKUIDelegate {
    let webView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(KiwixURLSchemeHandler(), forURLScheme: "kiwix")
        config.mediaTypesRequiringUserActionForPlayback = []
        return WKWebView(frame: .zero, configuration: config)
    }()
    private var textSizeAdjustFactorObserver: NSKeyValueObservation?
    
    convenience init(url: URL) {
        self.init()
        webView.load(URLRequest(url: url))
    }
    
    override func loadView() {
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        if #available(iOS 14.0, *) {
            navigationController?.isNavigationBarHidden = true
        }
        
        // observe webView font size adjust factor
        textSizeAdjustFactorObserver = UserDefaults.standard.observe(\.webViewTextSizeAdjustFactor) { _, _ in
            self.adjustTextSize()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        webView.setValue(view.safeAreaInsets, forKey: "_obscuredInsets")
    }
    
    func adjustTextSize() {
        let scale = UserDefaults.standard.webViewTextSizeAdjustFactor
        let javascript = String(format: "document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '%.0f%%'", scale * 100)
        webView.evaluateJavaScript(javascript, completionHandler: nil)
    }
    
    // MARK: - WKUIDelegate
    
    @available(iOS 13.0, *)
    func webView(_ webView: WKWebView,
                 contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo,
                 completionHandler: @escaping (UIContextMenuConfiguration?) -> Void) {
        guard let url = elementInfo.linkURL else { completionHandler(nil); return }
        if url.isKiwixURL {
            let config = UIContextMenuConfiguration(
                identifier: nil,
                previewProvider: { WebViewController(url: url) },
                actionProvider: { elements -> UIMenu? in
                    UIMenu(children: elements)
                }
            )
            completionHandler(config)
        } else {
            completionHandler(nil)
        }
    }
}
