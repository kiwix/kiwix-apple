//
//  WebViewController.swift
//  Kiwix
//
//  Created by Chris Li on 6/6/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import Cocoa
import WebKit

class WebViewController: NSViewController {

    @IBOutlet weak var webView: WebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let url = NSURL(string: "https://www.google.com")!
//        let request = NSURLRequest(URL: url)
//        webView.mainFrame.loadRequest(request)
    }
    
}
