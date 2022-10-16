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
    @EnvironmentObject var viewModel: ViewModel
    @EnvironmentObject var readingViewModel: ReadingViewModel
    
    func makeNSView(context: Context) -> WKWebView {
        let webView = readingViewModel.webView
        webView.allowsBackForwardNavigationGestures = true
        webView.configuration.userContentController.add(readingViewModel, name: "headings")
        webView.navigationDelegate = viewModel
        context.coordinator.setupObservers(webView)
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        guard let url = url, webView.url?.absoluteString != url.absoluteString else { return }
        webView.load(URLRequest(url: url))
    }
    
    static func dismantleNSView(_ webView: WKWebView, coordinator: WebViewCoordinator) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "headings")
    }
    
    func makeCoordinator() -> WebViewCoordinator { WebViewCoordinator(self) }
}
#elseif os(iOS)
struct WebView: UIViewControllerRepresentable {
    @Binding var url: URL?
    @EnvironmentObject var viewModel: ViewModel
    @EnvironmentObject var readingViewModel: ReadingViewModel
    
    func makeUIViewController(context: Context) -> WebViewController {
        let webView = readingViewModel.webView
        webView.allowsBackForwardNavigationGestures = true
        webView.configuration.defaultWebpagePreferences.preferredContentMode = .mobile  // for font adjustment to work
        webView.configuration.userContentController.add(readingViewModel, name: "headings")
        webView.navigationDelegate = viewModel
        context.coordinator.setupObservers(webView)
        return WebViewController(webView: webView)
    }
    
    func updateUIViewController(_ controller: WebViewController, context: Context) {
        guard let url = url, readingViewModel.webView.url?.absoluteString != url.absoluteString else { return }
        readingViewModel.webView.load(URLRequest(url: url))
    }
    
    static func dismantleUIViewController(_ controller: WebViewController, coordinator: WebViewCoordinator) {
        controller.view.subviews.forEach { $0.removeFromSuperview() }
    }

    func makeCoordinator() -> WebViewCoordinator { WebViewCoordinator(self) }
}

class WebViewController: UIViewController {
    convenience init(webView: WKWebView) {
        self.init(nibName: nil, bundle: nil)
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: webView.topAnchor),
            view.leftAnchor.constraint(equalTo: webView.leftAnchor),
            view.bottomAnchor.constraint(equalTo: webView.bottomAnchor),
            view.rightAnchor.constraint(equalTo: webView.rightAnchor)
        ])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let webView = view.subviews.first as? WKWebView else { return }
        webView.setValue(view.safeAreaInsets, forKey: "_obscuredInsets")
    }
}
#endif

extension WKWebView {
    func applyTextSizeAdjustment() {
        #if os(iOS)
        guard Defaults[.webViewPageZoom] != 1 else { return }
        let template = "document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust='%.0f%%'"
        let javascript = String(format: template, Defaults[.webViewPageZoom] * 100)
        evaluateJavaScript(javascript, completionHandler: nil)
        #endif
    }
}

class WebViewConfiguration: WKWebViewConfiguration {
    override init() {
        super.init()
        setURLSchemeHandler(KiwixURLSchemeHandler(), forURLScheme: "kiwix")
        userContentController = {
            let controller = WKUserContentController()
            if FeatureFlags.wikipediaDarkUserCSS,
               let path = Bundle.main.path(forResource: "wikipedia_dark", ofType: "css"),
               let css = try? String(contentsOfFile: path) {
                let source = """
                    var style = document.createElement('style');
                    style.innerHTML = `\(css)`;
                    document.head.appendChild(style);
                    """
                let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
                controller.addUserScript(script)
            }
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
            #if os(macOS)
            webView.pageZoom = change.newValue
            #elseif os(iOS)
            webView.applyTextSizeAdjustment()
            #endif
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
