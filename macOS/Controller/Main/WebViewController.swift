//
//  WebViewController.swift
//  macOS
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
        guard let id = ZimManager.shared.getReaderIDs().first,
            let mainPagePath = ZimManager.shared.getMainPagePath(bookID: id),
            let mainPageURL = URL(bookID: id, contentPath: mainPagePath) else {return}
        let request = URLRequest(url: mainPageURL)
        webView.mainFrame.load(request)
    }
    
    // MARK: - WebFrameLoadDelegate
    
    func webView(_ sender: WebView!, didFinishLoadFor frame: WebFrame!) {
        guard let controller = view.window?.windowController as? MainWindowController else {return}
        controller.titleTextField.stringValue = frame.dataSource?.pageTitle ?? ""
    }
}
