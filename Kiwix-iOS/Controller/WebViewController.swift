//
//  WebViewController.swift
//  Kiwix
//
//  Created by Chris Li on 5/2/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class WebViewController: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var webView: UIWebView!
    
    var page: WebViewControllerContentType?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.delegate = self
        
        guard let page = page else {return}
        switch page {
        case .DownloaderLearnMore:
            guard let url = NSBundle.mainBundle().URLForResource(page.rawValue, withExtension: "html") else {return}
            webView.loadRequest(NSURLRequest(URL: url))
            title = NSLocalizedString("Help: Downloader", comment: "Help page title")
        case .ImportBookLearnMore:
            guard let url = NSBundle.mainBundle().URLForResource(page.rawValue, withExtension: "html") else {return}
            webView.loadRequest(NSURLRequest(URL: url))
            title = NSLocalizedString("Help: Import Books", comment: "Help page title")
        case .About:
            guard let url = NSBundle.mainBundle().URLForResource(page.rawValue, withExtension: "html") else {return}
            webView.loadRequest(NSURLRequest(URL: url))
            title = NSLocalizedString("About", comment: "About page title")
        }
        
        guard let rootController = navigationController?.viewControllers.first else {return}
        if rootController == self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(WebViewController.dismissSelf))
        }
    }
    
    func dismissSelf() {
        dismissViewControllerAnimated(true, completion: nil)
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

enum WebViewControllerContentType: String {
    case DownloaderLearnMore, ImportBookLearnMore, About
}