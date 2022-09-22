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
        webView.load(URLRequest(url: url))
    }
    func makeCoordinator() -> Coordinator { Coordinator() }
    class Coordinator { var urlObserver: NSKeyValueObservation? }
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
