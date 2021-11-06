//
//  WebView.swift
//  macOS_SwiftUI
//
//  Created by Chris Li on 11/5/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI
import WebKit

struct WebView: NSViewRepresentable {
    @EnvironmentObject var viewModel: SceneViewModel
    
    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(KiwixURLSchemeHandler(), forURLScheme: "kiwix")
//        config.userContentController = {
//            let controller = WKUserContentController()
//            guard FeatureFlags.wikipediaDarkUserCSS,
//                  let path = Bundle.main.path(forResource: "wikipedia_dark", ofType: "css"),
//                  let css = try? String(contentsOfFile: path) else { return controller }
//            let source = """
//                var style = document.createElement('style');
//                style.innerHTML = `\(css)`;
//                document.head.appendChild(style);
//                """
//            let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
//            controller.addUserScript(script)
//            return controller
//        }()
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        guard let action = viewModel.action else { return }
        defer { viewModel.action = nil }
        switch action {
        case .back:
            nsView.goBack()
        case .forward:
            nsView.goForward()
        case .url(let url):
            nsView.load(URLRequest(url: url))
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        private let webView: WebView
        
        init(_ webView: WebView) {
            self.webView = webView
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            self.webView.viewModel.canGoBack = webView.canGoBack
            self.webView.viewModel.canGoForward = webView.canGoForward
            self.webView.viewModel.articleTitle = webView.title
            self.webView.viewModel.zimFileTitle = "zim file"
        }
    }
}

enum WebViewAction {
    case back, forward, url(URL)
}
