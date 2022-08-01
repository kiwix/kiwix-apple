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
class WebViewCoordinator: NSObject, WKNavigationDelegate {
    var canGoBackObserver: NSKeyValueObservation?
    var canGoForwardObserver: NSKeyValueObservation?
    var titleObserver: NSKeyValueObservation?
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
        webView.evaluateJavaScript("expandAllDetailTags(); getOutlineItems();")
    }
}

struct WebView: NSViewRepresentable {
    @Binding var url: URL?
    @EnvironmentObject var viewModel: ReadingViewModel
    
    func makeNSView(context: Context) -> WKWebView {
        let webView = WebViewCoordinator.createWebView()
        webView.configuration.userContentController.add(viewModel, name: "headings")
        webView.navigationDelegate = context.coordinator
        viewModel.webView = webView
        context.coordinator.canGoBackObserver = webView.observe(\.canGoBack) { webView, _ in
            viewModel.canGoBack = webView.canGoBack
        }
        context.coordinator.canGoForwardObserver = webView.observe(\.canGoForward) { webView, _ in
            viewModel.canGoForward = webView.canGoForward
        }
        context.coordinator.titleObserver = webView.observe(\.title) { webView, _ in
            viewModel.articleTitle = webView.title ?? ""
        }
        context.coordinator.urlObserver = webView.observe(\.url) { webView, _ in
            guard webView.url?.absoluteString != url?.absoluteString else { return }
            url = webView.url
        }
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        guard let url = url, webView.url?.absoluteString != url.absoluteString else { return }
        webView.load(URLRequest(url: url))
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
