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
    @EnvironmentObject var viewModel: ReaderViewModel
    
    func makeNSView(context: Context) -> WKWebView {
        context.coordinator.urlObserver = viewModel.webView.observe(\.url) { webView, _ in
            guard webView.url?.absoluteString != url?.absoluteString else { return }
            url = webView.url
        }
        return viewModel.webView
    }
    func updateNSView(_ webView: WKWebView, context: Context) {
        guard let url = url, webView.url?.absoluteString != url.absoluteString else { return }
        viewModel.load(url)
    }
    func makeCoordinator() -> Coordinator { Coordinator() }
    class Coordinator { var urlObserver: NSKeyValueObservation? }
}
#elseif os(iOS)
struct WebView: UIViewRepresentable {
    @Binding var url: URL?
    @EnvironmentObject var viewModel: ReaderViewModel
    
    func makeUIView(context: Context) -> WKWebView {
        context.coordinator.urlObserver = viewModel.webView.observe(\.url) { webView, _ in
            guard webView.url?.absoluteString != url?.absoluteString else { return }
            url = webView.url
        }
        return viewModel.webView
    }
    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let url = url, webView.url?.absoluteString != url.absoluteString else { return }
        viewModel.load(url)
    }
    func makeCoordinator() -> Coordinator { Coordinator() }
    class Coordinator { var urlObserver: NSKeyValueObservation? }
}
#endif
