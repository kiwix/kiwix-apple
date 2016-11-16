//
//  WebViewController.swift
//  Kiwix
//
//  Created by Chris Li on 5/2/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit

class WebViewControllerOld: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var webView: UIWebView!
    
    var page: WebViewControllerContentType?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.delegate = self
        
        guard let page = page else {return}
        switch page {
        case .DownloaderLearnMore:
            guard let url = Bundle.main.url(forResource: page.rawValue, withExtension: "html") else {return}
            webView.loadRequest(URLRequest(url: url))
            title = NSLocalizedString("Help: Downloader", comment: "Help page title")
        case .ImportBookLearnMore:
            guard let url = Bundle.main.url(forResource: page.rawValue, withExtension: "html") else {return}
            webView.loadRequest(URLRequest(url: url))
            title = NSLocalizedString("Help: Import Books", comment: "Help page title")
        case .About:
            guard let url = Bundle.main.url(forResource: page.rawValue, withExtension: "html") else {return}
            webView.loadRequest(URLRequest(url: url))
            title = NSLocalizedString("About", comment: "About page title")
        }
        
        guard let rootController = navigationController?.viewControllers.first else {return}
        if rootController == self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissSelf))
        }
    }
    
    func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func downButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: -  UIWebViewDelegate
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if navigationType == .linkClicked {
            UIApplication.shared.openURL(request.url!)
            return false
        }
        return true
    }
}

enum WebViewControllerContentType: String {
    case DownloaderLearnMore, ImportBookLearnMore, About
}
