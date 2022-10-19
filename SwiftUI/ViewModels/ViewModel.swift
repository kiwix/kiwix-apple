//
//  ViewModel.swift
//  Kiwix
//
//  Created by Chris Li on 9/3/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import WebKit

import Defaults

class ViewModel: NSObject, ObservableObject, WKNavigationDelegate, WKUIDelegate {
    @Published var activeAlert: ActiveAlert?
    @Published var activeSheet: ActiveSheet?
    @Published var navigationItem: NavigationItem? = .reading
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { decisionHandler(.cancel); return }
        if url.isKiwixURL, let redirectedURL = ZimFileService.shared.getRedirectedURL(url: url) {
            DispatchQueue.main.async { webView.load(URLRequest(url: redirectedURL)) }
            decisionHandler(.cancel)
        } else if url.isKiwixURL {
            decisionHandler(.allow)
        } else if url.scheme == "http" || url.scheme == "https" {
            switch Defaults[.externalLinkLoadingPolicy] {
            case .alwaysAsk:
                activeAlert = .externalLinkAsk(url: url)
            case .alwaysLoad:
                #if os(macOS)
                NSWorkspace.shared.open(url)
                #elseif os(iOS)
                activeSheet = .safari(url: url)
                #endif
            case .neverLoad:
                activeAlert = .externalLinkNotLoading
            }
            decisionHandler(.cancel)
        } else if url.scheme == "geo" {
            let coordinate = url.absoluteString.replacingOccurrences(of: "geo:", with: "")
            if let url = URL(string: "http://maps.apple.com/?ll=\(coordinate)") {
                #if os(macOS)
                NSWorkspace.shared.open(url)
                #elseif os(iOS)
                UIApplication.shared.open(url)
                #endif
            }
            decisionHandler(.cancel)
        } else {
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("expandAllDetailTags(); getOutlineItems();")
        webView.applyTextSizeAdjustment()
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        activeAlert = .articleFailedToLoad
    }
    
    // MARK: - WKUIDelegate
    
    #if os(iOS)
    func webView(_ webView: WKWebView,
                 contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo,
                 completionHandler: @escaping (UIContextMenuConfiguration?) -> Void) {
        guard let url = elementInfo.linkURL, url.isKiwixURL else { completionHandler(nil); return }
        let configuration = UIContextMenuConfiguration(
            previewProvider: {
                let webView = WKWebView(frame: .zero, configuration: WebViewConfiguration())
                webView.load(URLRequest(url: url))
                return WebViewController(webView: webView)
            },actionProvider: { suggestedActions in
                var actions = [UIAction]()
                
                // open url
                let openAction = UIAction(title: "Open", image: UIImage(systemName: "doc.richtext")) { _ in
                    webView.load(URLRequest(url: url))
                }
                actions.append(openAction)
                
                // bookmark
                let bookmarkAction: UIAction = {
                    let context = Database.shared.container.viewContext
                    let predicate = NSPredicate(format: "articleURL == %@", url as CVarArg)
                    let request = Bookmark.fetchRequest(predicate: predicate)
                    if let bookmarks = try? context.fetch(request), !bookmarks.isEmpty {
                        return UIAction(title: "Remove Bookmark", image: UIImage(systemName: "star.slash.fill")) { _ in
                            BookmarkOperations.delete(url, withNotification: false)
                        }
                    } else {
                        return UIAction(title: "Bookmark", image: UIImage(systemName: "star")) { _ in
                            BookmarkOperations.create(url, withNotification: false)
                        }
                    }
                }()
                actions.append(bookmarkAction)
                
                return UIMenu(children: actions)
            }
        )
        completionHandler(configuration)
    }
    #endif
}
