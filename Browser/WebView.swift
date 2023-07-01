//
//  WebView.swift
//  Kiwix
//
//  Created by Chris Li on 11/5/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import CoreData
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
    @EnvironmentObject private var viewModel: BrowserViewModel
        
    func makeUIViewController(context: Context) -> WebViewController {
        WebViewController(tabID: viewModel.tabID, webView: viewModel.webView)
    }
    
    func updateUIViewController(_ controller: WebViewController, context: Context) { }
    
    static func dismantleUIViewController(_ controller: WebViewController, coordinator: ()) {
        guard let interactionState = controller.webView.interactionState as? Data else { return }
        Database.performBackgroundTask { context in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            guard let tab = try? context.fetch(Tab.fetchRequest(id: controller.tabID)).first else { return }
            tab.interactionState = interactionState
            try? context.save()
        }
    }
}

class WebViewController: UIViewController {
    let tabID: UUID
    let webView: WKWebView
    
    init(tabID: UUID, webView: WKWebView) {
        self.tabID = tabID
        self.webView = webView
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupWebView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        webView.setValue(view.safeAreaInsets, forKey: "_obscuredInsets")
    }
    
    /// Install web view, and setup property observers
    private func setupWebView() {
        guard !view.subviews.contains(webView) else { return }
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            view.leftAnchor.constraint(equalTo: webView.leftAnchor),
            view.bottomAnchor.constraint(equalTo: webView.bottomAnchor),
            view.rightAnchor.constraint(equalTo: webView.rightAnchor)
        ])
        
        let topSafeAreaConstraint = view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: webView.topAnchor)
        topSafeAreaConstraint.isActive = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            topSafeAreaConstraint.isActive = false
            let topConstraint = self.view.topAnchor.constraint(equalTo: self.webView.topAnchor)
            topConstraint.isActive = true
        }
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
