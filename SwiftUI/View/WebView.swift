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
struct WebView: NSViewRepresentable {
    @Binding var url: URL?
    let webView: WKWebView
    
    func makeNSView(context: Context) -> WKWebView { webView }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        guard let url = url, nsView.url != url else { return }
        nsView.load(URLRequest(url: url))
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(view: self) }
    
    class Coordinator {
        private let urlObserver: NSKeyValueObservation
        
        init(view: WebView) {
            urlObserver = view.webView.observe(\.url) { webview, _ in view.url = webview.url }
        }
    }
}
#elseif os(iOS)
struct WebView: UIViewRepresentable {
    @Binding var url: URL?
    
    func makeUIView(context: Context) -> WKWebView {
        WKWebView()
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        
    }
}
#endif
