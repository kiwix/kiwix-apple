//
//  WebView.swift
//  Kiwix
//
//  Created by Chris Li on 10/19/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import SwiftUI
import WebKit

@available(iOS 14.0, *)
struct WebView: UIViewRepresentable {
    private let webView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(KiwixURLSchemeHandler(), forURLScheme: "kiwix")
        config.mediaTypesRequiringUserActionForPlayback = []
        return WKWebView(frame: .zero, configuration: config)
    }()

    func makeUIView(context: Context) -> WKWebView {
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        
    }
    
    func load(url: URL) {
        webView.load(URLRequest(url: url))
    }
}
