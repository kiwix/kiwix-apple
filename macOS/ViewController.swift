//
//  ViewController.swift
//  Kiwix
//
//  Created by Chris Li on 2/12/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import Cocoa
import WebKit

class ViewController: NSViewController {
    @IBOutlet weak var webView: WebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        let url = URL(string: "https://www.google.com")
        let request = URLRequest(url: url!)
        webView.mainFrame.load(request)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

