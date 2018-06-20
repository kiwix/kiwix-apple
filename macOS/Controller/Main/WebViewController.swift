//
//  WebViewController.swift
//  Kiwix
//
//  Created by Chris Li on 8/22/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import Cocoa
import WebKit

class WebViewController: NSViewController, WebFrameLoadDelegate {
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
    
    func webView(_ sender: WebView!, didFinishLoadFor frame: WebFrame!) {
        guard let controller = view.window?.windowController as? MainWindowController else {return}
        controller.searchField.title = frame.dataSource?.pageTitle
    }
}
