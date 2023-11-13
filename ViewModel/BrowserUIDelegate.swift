//
//  BrowserUIDelegate.swift
//  Kiwix
//
//  Copyright © 2023 Chris Li. All rights reserved.
//

import WebKit

final class BrowserUIDelegate: NSObject, WKUIDelegate {

    @Published private(set) var externalURL: URL?

#if os(macOS)
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {

        guard navigationAction.targetFrame == nil else { return nil }
        guard let newUrl = navigationAction.request.url else { return nil }

        // open external link in default browser
        guard newUrl.isExternal == false else {
            externalURL = newUrl
            return nil
        }

        // create new tab
        guard let currentWindow = NSApp.keyWindow,
              let windowController = currentWindow.windowController else { return nil }
        // store the new url in a static way
        BrowserViewModel.urlForNewTab = newUrl
        // this creates a new BrowserViewModel
        windowController.newWindowForTab(self)
        // now reset the static url to nil, as the new BrowserViewModel already has it
        BrowserViewModel.urlForNewTab = nil
        guard let newWindow = NSApp.keyWindow, currentWindow != newWindow else { return nil }
        currentWindow.addTabbedWindow(newWindow, ordered: .above)
        return nil
    }
#endif

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
            }, actionProvider: { suggestedActions in
                var actions = [UIAction]()

                // open url
                actions.append(
                    UIAction(title: "Open", image: UIImage(systemName: "doc.text")) { _ in
                        webView.load(URLRequest(url: url))
                    }
                )
                actions.append(
                    UIAction(title: "Open in New Tab", image: UIImage(systemName: "doc.badge.plus")) { _ in
                        NotificationCenter.openURL(url, inNewTab: true)
                    }
                )

                // bookmark
                let bookmarkAction: UIAction = {
                    let context = Database.viewContext
                    let predicate = NSPredicate(format: "articleURL == %@", url as CVarArg)
                    let request = Bookmark.fetchRequest(predicate: predicate)
                    if let bookmarks = try? context.fetch(request), !bookmarks.isEmpty {
                        return UIAction(title: "Remove Bookmark", image: UIImage(systemName: "star.slash.fill")) { _ in
                            self.deleteBookmark(url: url)
                        }
                    } else {
                        return UIAction(title: "Bookmark", image: UIImage(systemName: "star")) { _ in
                            self.createBookmark(url: url)
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
