//
//  TabController.swift
//  Kiwix
//
//  Created by Chris Li on 4/6/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class TabController: UIViewController, UIWebViewDelegate {
    @IBOutlet weak var webView: UIWebView!
    weak var delegate: TabControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.delegate = self
    }
    
    // MARK: - UIWebViewDelegate
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        delegate?.didFinishLoad(tab: self)
    }

}

protocol TabControllerDelegate: class {
    func didFinishLoad(tab: TabController)
}
