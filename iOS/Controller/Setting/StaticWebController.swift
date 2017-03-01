//
//  StaticWebController.swift
//  Kiwix
//
//  Created by Chris Li on 1/20/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import SafariServices

class StaticWebController: UIViewController, UIWebViewDelegate, SFSafariViewControllerDelegate {
    
    @IBOutlet weak var webView: UIWebView!
    private var url: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        webView.delegate = self
        
        guard let url = url, webView.request?.url != url else {return}
        webView.loadRequest(URLRequest(url: url))
    }
    
    func load(htmlFileName: String) {
        url = Bundle.main.url(forResource: htmlFileName, withExtension: "html")
        guard let url = url, webView != nil, webView.request?.url != url else {return}
        webView.loadRequest(URLRequest(url: url))
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        guard let url = request.url else {return false}
        if url == self.url {
            return true
        } else {
            let controller = SFSafariViewController(url: url)
            controller.delegate = self
            present(controller, animated: true, completion: nil)
            return false
        }
    }
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    

}
