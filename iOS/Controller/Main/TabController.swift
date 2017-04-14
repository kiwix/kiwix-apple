//
//  TabController.swift
//  Kiwix
//
//  Created by Chris Li on 4/6/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class TabController: UIViewController, UIWebViewDelegate, UIScrollViewDelegate {
    @IBOutlet weak var webView: UIWebView!
    weak var delegate: TabControllerDelegate?
    private(set) var article: Article?
    private var offset = [URL: CGFloat]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.delegate = self
        webView.allowsLinkPreview = true
        webView.scrollView.delegate = self
    }
    
    // MARK: - UIWebViewDelegate
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        guard let url = request.url else {return false}
        if url.isKiwixURL {
            return true
        } else if url.scheme == "pagescroll" {
            let components = URLComponents(string: url.absoluteString)
            guard let query = components?.queryItems,
                let startStr = query[0].value, let start = Int(startStr),
                let lengthStr = query[1].value, let length = Int(lengthStr) else {
                    return false
            }
            delegate?.pageDidScroll(start: start, length: length)
            return false
        } else {
            delegate?.didTapOnExternalLink(url: url)
            return false
        }
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        URLResponseCache.shared.start()
        print(webView.canGoBack)
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        URLResponseCache.shared.stop()
        
        JS.inject(webView: webView)
        JS.preventDefaultLongTap(webView: webView)
        JS.startTOCCallBack(webView: webView)
        JS.adjustFontSizeIfNeeded(webView: webView)
        
        guard let url = webView.request?.url,
            let article = Article.fetch(url: url, context: AppDelegate.persistentContainer.viewContext) else {return}
        guard let title = JS.getTitle(from: webView) else {return}
        article.title = title
        article.snippet = JS.getSnippet(from: webView)
        article.lastReadDate = Date()
        article.thumbImagePath = URLResponseCache.shared.firstImage()?.path
        self.article = article
        
        if let url = article.url, let offset = offset[url] {
            webView.scrollView.contentOffset = CGPoint(x: 0, y: offset * webView.scrollView.contentSize.height)
        }
        
        delegate?.didFinishLoading(tab: self)
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        // 404
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard let url = article?.url else {return}
        offset[url] = scrollView.contentOffset.y / scrollView.contentSize.height
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let url = article?.url else {return}
        offset[url] = scrollView.contentOffset.y / scrollView.contentSize.height
    }

}

protocol TabControllerDelegate: class {
    func didFinishLoading(tab: TabController)
    func didTapOnExternalLink(url: URL)
    func pageDidScroll(start: Int, length: Int)
}
