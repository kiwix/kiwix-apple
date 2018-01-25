//
//  WebViewControllerProtocols.swift
//  iOS
//
//  Created by Chris Li on 1/10/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit


protocol WebViewController {
    weak var delegate: WebViewControllerDelegate? {get set}
    var canGoBack: Bool {get}
    var canGoForward: Bool {get}
    var currentURL: URL? {get}
    var currentTitle: String? {get}
    
    func goBack()
    func goForward()
    func load(url: URL)
    func extractSnippet(completion: @escaping ((String?) -> Void))
    func extractImageURLs(completion: @escaping (([URL]) -> Void))
    func extractTableOfContents(completion: @escaping ((URL?, [TableOfContentItem]) -> Void))
    func scrollToTableOfContentItem(index: Int)
}

protocol WebViewControllerDelegate: class {
    func webViewDidFinishLoading(controller: WebViewController)
}
