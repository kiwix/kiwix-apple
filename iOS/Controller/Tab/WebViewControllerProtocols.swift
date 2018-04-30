//
//  WebViewControllerProtocols.swift
//  iOS
//
//  Created by Chris Li on 1/10/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit


protocol WebViewController {
    var delegate: WebViewControllerDelegate? {get set}
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
    func adjustFontSize(scale: Double)
}

protocol WebViewControllerDelegate: class {
    func webViewDidFinishLoading(controller: WebViewController)
}

class ExternalLinkAlertController: UIAlertController {
    convenience init(policy: ExternalLinkLoadingPolicy, action: @escaping (()->Void)) {
        let message: String = {
            switch policy {
            case .alwaysAsk:
                return NSLocalizedString("An external link is tapped, do you wish to load the link via Internet?", comment: "External Link Alert")
            case .neverLoad:
                return NSLocalizedString("An external link is tapped. However, your current setting does not allow it to be loaded.", comment: "External Link Alert")
            default:
                return ""
            }
        }()
        self.init(title: NSLocalizedString("External Link", comment: "External Link Alert"), message: message, preferredStyle: .alert)
        if policy == .alwaysAsk {
            addAction(UIAlertAction(title: NSLocalizedString("Load the link", comment: "External Link Alert"), style: .default, handler: { _ in
                action()
            }))
            addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "External Link Alert"), style: .cancel, handler: nil))
        } else if policy == .neverLoad {
            addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "External Link Alert"), style: .cancel, handler: nil))
        }
        
    }
}
