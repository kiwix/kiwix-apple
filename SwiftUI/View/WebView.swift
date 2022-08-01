//
//  WebView.swift
//  Kiwix
//
//  Created by Chris Li on 11/5/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI
import WebKit

extension WKWebView {
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
}

#if os(macOS)
struct WebView: NSViewRepresentable {
    @Binding var articleTitle: String
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var navigationAction: ReadingViewNavigationAction?
    @Binding var url: URL?
    
    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView.createWebView()
        context.coordinator.urlObserver = webView.observe(\.url) { webView, _ in
            guard webView.url?.absoluteString != url?.absoluteString else { return }
            url = webView.url
        }
        context.coordinator.titleObserver = webView.observe(\.title) { webView, _ in
            articleTitle = webView.title ?? ""
            canGoBack = webView.canGoBack
            canGoForward = webView.canGoForward
        }
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        if navigationAction == .goBack {
            webView.goBack()
            DispatchQueue.main.async { navigationAction = nil }
        } else if navigationAction == .goForward {
            webView.goForward()
            DispatchQueue.main.async { navigationAction = nil }
        } else if let url = url, webView.url?.absoluteString != url.absoluteString {
            webView.load(URLRequest(url: url))
        }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator() }
    
    class Coordinator {
        var urlObserver: NSKeyValueObservation?
        var titleObserver: NSKeyValueObservation?
    }
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
