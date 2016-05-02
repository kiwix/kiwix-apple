//
//  WebViewVC.swift
//  Kiwix
//
//  Created by Chris Li on 5/2/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class WebViewVC: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var webView: UIWebView!
    
    var page: WebViewVCHTML?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.delegate = self
        
        guard let page = page else {return}
        switch page {
        case .DownloaderLearnMore:
            guard let url = NSBundle.mainBundle().URLForResource(page.rawValue, withExtension: "html") else {return}
            webView.loadRequest(NSURLRequest(URL: url))
            title = NSLocalizedString("Help: Downloader", comment: "Help page title")
        case .LocalBookLearnMore:
            guard let url = NSBundle.mainBundle().URLForResource(page.rawValue, withExtension: "html") else {return}
            webView.loadRequest(NSURLRequest(URL: url))
            title = NSLocalizedString("Help: Local Books", comment: "Help page title")
        }
    }
    
    @IBAction func downButtonTapped(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: -  UIWebViewDelegate
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if navigationType == .LinkClicked {
            UIApplication.sharedApplication().openURL(request.URL!)
            return false
        }
        return true
    }
}

enum WebViewVCHTML: String {
    case DownloaderLearnMore, LocalBookLearnMore
}