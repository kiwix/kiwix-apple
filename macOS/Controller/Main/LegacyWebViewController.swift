//
//  WebViewController.swift
//  Kiwix
//
//  Created by Chris Li on 8/22/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import Cocoa
import WebKit

class LegacyWebViewController: NSViewController, WebFrameLoadDelegate {
    @IBOutlet weak var webView: WebView!
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        webView.frameLoadDelegate = self
        webView.enclosingScrollView?.verticalScrollElasticity = .allowed
        webView.enclosingScrollView?.horizontalScrollElasticity = .allowed
    }
    
    func loadMainPage() {
        guard let id = ZimMultiReader.shared.ids.first,
            let mainPageURL = ZimMultiReader.shared.getMainPageURL(zimFileID: id) else {return}
        load(url: mainPageURL)
    }
    
    func load(url: URL) {
        if webView.isHidden {webView.isHidden = false}
        let request = URLRequest(url: url)
        webView.mainFrame.load(request)
    }
    
    // MARK: - WebFrameLoadDelegate
    
    func webView(_ sender: WebView!, didStartProvisionalLoadFor frame: WebFrame!) {
        guard let url = URL(string: webView.mainFrameURL) else { webView.stopLoading(nil); return }
        if url.isKiwixURL {
            guard let zimFileID = url.host else { webView.stopLoading(nil); return }
            if let redirectedPath = ZimMultiReader.shared.getRedirectedPath(zimFileID: zimFileID, contentPath: url.path),
                let redirectedURL = URL(bookID: zimFileID, contentPath: redirectedPath) {
                DispatchQueue.main.async {
                    self.load(url: redirectedURL)
                }
                webView.stopLoading(nil)
            }
        } else if url.scheme == "http" || url.scheme == "https" {
            webView.stopLoading(nil)
        } else {
            webView.stopLoading(nil)
        }
    }
    
    func webView(_ sender: WebView!, didFinishLoadFor frame: WebFrame!) {
        guard let controller = view.window?.windowController as? MainWindowController else {return}
        controller.searchField.title = frame.dataSource?.pageTitle
    }
}
