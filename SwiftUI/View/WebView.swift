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
    @EnvironmentObject var viewModel: ReadingViewModel
    
    func makeNSView(context: Context) -> WKWebView {
        context.coordinator.urlObserver = context.coordinator.webView.observe(\.url) { webView, _ in
            guard webView.url?.absoluteString != url?.absoluteString else { return }
            url = webView.url
        }
        return context.coordinator.webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        guard let url = url, webView.url?.absoluteString != url.absoluteString else { return }
        webView.load(URLRequest(url: url))
    }
    
    static func dismantleNSView(_ nsView: WKWebView, coordinator: WebViewCoordinator) {
        coordinator.viewModel?.webViewInteractionState = coordinator.webView.interactionState
    }
    
    func makeCoordinator() -> WebViewCoordinator { WebViewCoordinator(viewModel) }
}
#elseif os(iOS)
struct WebView: UIViewControllerRepresentable {
    @Binding var url: URL?
    @EnvironmentObject var viewModel: ReadingViewModel
    
    func makeUIViewController(context: Context) -> WebViewController {
        let controller = WebViewController(webView: context.coordinator.webView)
        context.coordinator.urlObserver = context.coordinator.webView.observe(\.url) { webView, _ in
            guard webView.url?.absoluteString != url?.absoluteString else { return }
            url = webView.url
        }
        return controller
    }
    
    func updateUIViewController(_ controller: WebViewController, context: Context) {
        guard let url = url, context.coordinator.webView.url?.absoluteString != url.absoluteString else { return }
        context.coordinator.webView.load(URLRequest(url: url))
    }
    
    static func dismantleUIViewController(_ uiViewController: WebViewController, coordinator: WebViewCoordinator) {
        if #available(iOS 15.0, *) {
            coordinator.viewModel?.webViewInteractionState = coordinator.webView.interactionState
        }
    }
    
    func makeCoordinator() -> WebViewCoordinator { WebViewCoordinator(viewModel) }
}

class WebViewController: UIViewController {
    private let webView: WKWebView
    
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

class WebViewCoordinator {
    var canGoBackObserver: NSKeyValueObservation?
    var canGoForwardObserver: NSKeyValueObservation?
    var titleObserver: NSKeyValueObservation?
    var urlObserver: NSKeyValueObservation?
    
    weak var viewModel: ReadingViewModel?
    
    let webView: WKWebView = {
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
    }()
    
    init(_ viewModel: ReadingViewModel) {
        self.viewModel = viewModel
        viewModel.webView = webView
        
        webView.navigationDelegate = viewModel
        webView.configuration.userContentController.add(viewModel, name: "headings")
        canGoBackObserver = webView.observe(\.canGoBack) { webView, _ in
            viewModel.canGoBack = webView.canGoBack
        }
        canGoForwardObserver = webView.observe(\.canGoForward) { webView, _ in
            viewModel.canGoForward = webView.canGoForward
        }
        titleObserver = webView.observe(\.title) { webView, _ in
            guard let title = webView.title, !title.isEmpty,
                  let zimFileID = webView.url?.host,
                  let zimFile = try? Database.shared.container.viewContext.fetch(
                    ZimFile.fetchRequest(predicate: NSPredicate(format: "fileID == %@", zimFileID))
                  ).first else { return }
            viewModel.articleTitle = title
            viewModel.zimFileName = zimFile.name
        }
    }
}
