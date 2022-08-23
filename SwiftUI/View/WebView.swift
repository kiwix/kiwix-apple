//
//  WebView.swift
//  Kiwix
//
//  Created by Chris Li on 11/5/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI
import WebKit

import Defaults

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
    @EnvironmentObject var readingViewModel: ReadingViewModel
    
    func makeUIViewController(context: Context) -> WebViewController {
        let controller = WebViewController()
        controller.webView.allowsBackForwardNavigationGestures = true
        controller.webView.configuration.userContentController.add(readingViewModel, name: "headings")
        controller.webView.navigationDelegate = readingViewModel
        readingViewModel.webView = controller.webView
        context.coordinator.setupObservers(controller.webView)
        return controller
    }
    
    func updateUIViewController(_ controller: WebViewController, context: Context) {
        guard let url = url, controller.webView.url?.absoluteString != url.absoluteString else { return }
        controller.webView.load(URLRequest(url: url))
    }
    
    static func dismantleUIViewController(_ webViewController: WebViewController, coordinator: WebViewCoordinator) {
        if #available(iOS 15.0, *) {
            coordinator.view.readingViewModel.webViewInteractionState = webViewController.webView.interactionState
        }
    }
    
    func makeCoordinator() -> WebViewCoordinator { WebViewCoordinator(self) }
}

class WebViewController: UIViewController {
    let webView: WKWebView = WKWebView(frame: .zero, configuration: WebViewConfiguration())
    
    override func loadView() {
        view = webView
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        webView.setValue(view.safeAreaInsets, forKey: "_obscuredInsets")
    }
}
#endif

class WebViewConfiguration: WKWebViewConfiguration {
    override init() {
        super.init()
        setURLSchemeHandler(KiwixURLSchemeHandler(), forURLScheme: "kiwix")
        userContentController = {
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
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class WebViewCoordinator {
    var canGoBackObserver: NSKeyValueObservation?
    var canGoForwardObserver: NSKeyValueObservation?
    var pageZoomObserver: Defaults.Observation?
    var titleObserver: NSKeyValueObservation?
    var urlObserver: NSKeyValueObservation?
    
    let view: WebView
    
    init(_ view: WebView) {
        self.view = view
    }
    
    func setupObservers(_ webView: WKWebView) {
        canGoBackObserver = webView.observe(\.canGoBack) { [unowned self] webView, _ in
            self.view.readingViewModel.canGoBack = webView.canGoBack
        }
        canGoForwardObserver = webView.observe(\.canGoForward) { [unowned self] webView, _ in
            self.view.readingViewModel.canGoForward = webView.canGoForward
        }
        pageZoomObserver = Defaults.observe(.webViewPageZoom) { change in
            webView.pageZoom = change.newValue
        }
        urlObserver = webView.observe(\.url) { [unowned self] webView, _ in
            guard webView.url?.absoluteString != self.view.url?.absoluteString else { return }
            self.view.url = webView.url
        }
        titleObserver = webView.observe(\.title) { [unowned self] webView, _ in
            guard let title = webView.title, !title.isEmpty,
                  let zimFileID = webView.url?.host,
                  let zimFile = try? Database.shared.container.viewContext.fetch(
                    ZimFile.fetchRequest(predicate: NSPredicate(format: "fileID == %@", zimFileID))
                  ).first else { return }
            self.view.readingViewModel.articleTitle = title
            self.view.readingViewModel.zimFileName = zimFile.name
        }
    }
}
