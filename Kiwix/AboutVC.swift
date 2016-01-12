//
//  AboutVC.swift
//  Kiwix
//
//  Created by Chris on 1/3/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class AboutVC: UIViewController {

    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let url = NSBundle.mainBundle().URLForResource("about", withExtension: "html") else {return}
        webView.loadRequest(NSURLRequest(URL: url))
        
    }

}