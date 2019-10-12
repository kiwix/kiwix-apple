//
//  WebViewController.swift
//  macOS
//
//  Created by Chris Li on 10/12/19.
//  Copyright © 2019 Chris Li. All rights reserved.
//

import Cocoa
import WebKit

class WebViewController: NSViewController {
    @IBOutlet weak var webView: WKWebView!
    
    func load(url: URL) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    func loadMainPage(id: ZimFileID) {
        
    }
}
