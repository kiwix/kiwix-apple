//
//  WebView.swift
//  Kiwix
//
//  Created by Chris Li on 11/5/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI
import WebKit

#if os(macOS)
class WebViewCoordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    var urlObserver: NSKeyValueObservation?
    let view: WebView
    
    static func createWebView() -> WKWebView {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(KiwixURLSchemeHandler(), forURLScheme: "kiwix")
        config.userContentController = {
            let controller = WKUserContentController()
            guard FeatureFlags.wikipediaDarkUserCSS,
                  let path = Bundle.main.path(forResource: "wikipedia_dark", ofType: "css"),
                  let css = try? String(contentsOfFile: path) else { return controller }
            let source = """
                var style = document.createElement('style');
                style.innerHTML = `\(css)`;
                document.head.appendChild(style);
                """
            let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
            controller.addUserScript(script)
            if let url = Bundle.main.url(forResource: "injection", withExtension: "js"),
               let javascript = try? String(contentsOf: url) {
                let script = WKUserScript(source: javascript, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
                controller.addUserScript(script)
            }
            return controller
        }()
        return WKWebView(frame: .zero, configuration: config)
    }
    
    init(_ view: WebView) {
        self.view = view
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        view.articleTitle = webView.title ?? ""
        view.canGoBack = webView.canGoBack
        view.canGoForward = webView.canGoForward
        webView.evaluateJavaScript("expandAllDetailTags(); getOutlineItems();")
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "headings", let headings = message.body as? [[String: String]] {
            DispatchQueue.global(qos: .userInitiated).async {
                let allLevels = headings.compactMap { Int($0["tag"]?.suffix(1) ?? "") }
                let offset = allLevels.filter({ $0 == 1 }).count == 1 ? 2 : allLevels.min() ?? 0
                self.view.outlineItems = headings.enumerated().compactMap { index, heading in
                    guard let id = heading["id"],
                          let text = heading["text"],
                          let tag = heading["tag"],
                          let level = Int(tag.suffix(1)) else { return nil }
                    return OutlineItem(id: id, index: index, text: text, level: max(level - offset, 0))
                }
            }
        }
    }
}

struct WebView: NSViewRepresentable {
    @Binding var articleTitle: String
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var navigationAction: ReadingViewNavigationAction?
    @Binding var outlineItems: [OutlineItem]
    @Binding var url: URL?
    
    func makeNSView(context: Context) -> WKWebView {
        let webView = WebViewCoordinator.createWebView()
        webView.configuration.userContentController.add(context.coordinator, name: "headings")
        context.coordinator.urlObserver = webView.observe(\.url) { webView, _ in
            guard webView.url?.absoluteString != url?.absoluteString else { return }
            url = webView.url
        }
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        if navigationAction == .goBack {
            webView.goBack()
            DispatchQueue.main.async { navigationAction = nil }
        } else if navigationAction == .goForward {
            webView.goForward()
            DispatchQueue.main.async { navigationAction = nil }
        } else if case let .outlineItem(id) = navigationAction {
            webView.evaluateJavaScript("scrollToHeading('\(id)')")
        } else if let url = url, webView.url?.absoluteString != url.absoluteString {
            webView.load(URLRequest(url: url))
        }
    }
    
    func makeCoordinator() -> WebViewCoordinator { WebViewCoordinator(self) }
}
#elseif os(iOS)
struct WebView: UIViewControllerRepresentable {
    @Binding var url: URL?
    @EnvironmentObject var viewModel: ReaderViewModel
    
    func makeUIViewController(context: Context) -> WebViewController {
        context.coordinator.urlObserver = viewModel.webView.observe(\.url) { webView, _ in
            guard webView.url?.absoluteString != url?.absoluteString else { return }
            url = webView.url
        }
        return WebViewController(webView: viewModel.webView)
    }
    
    func updateUIViewController(_ webViewController: WebViewController, context: Context) {
        guard let url = url, viewModel.webView.url?.absoluteString != url.absoluteString else { return }
        viewModel.webView.load(URLRequest(url: url))
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var urlObserver: NSKeyValueObservation?
    }
}

class WebViewController: UIViewController {
    let webView: WKWebView
    
    init(webView: WKWebView) {
        self.webView = webView
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = webView
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        webView.setValue(view.safeAreaInsets, forKey: "_obscuredInsets")
    }
}
#endif
