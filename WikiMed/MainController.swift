//
//  ViewController.swift
//  WikiMed
//
//  Created by Chris Li on 9/6/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import WebKit

class MainController: UIViewController {
    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadMainPage()
    }
    
    func loadMainPage() {
        guard let id = ZimManager.shared.getReaderIDs().first,
            let url = ZimManager.shared.getMainPageURL(bookID: id) else {return}
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    
}

