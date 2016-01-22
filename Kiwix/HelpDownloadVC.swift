//
//  HelpDownloadVC.swift
//  Kiwix
//
//  Created by Chris Li on 1/17/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class HelpDownloadVC: UIViewController {

    @IBOutlet weak var webView: UIWebView!
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let url = NSBundle.mainBundle().URLForResource("how_download_works", withExtension: "html") else {return}
        webView.loadRequest(NSURLRequest(URL: url))
    }
}
