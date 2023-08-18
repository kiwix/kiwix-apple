//
//  WebView.swift
//  Kiwix
//
//  Created by Chris Li on 11/5/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import Combine
import CoreData
import SwiftUI
import WebKit

import Defaults

#if os(macOS)
struct WebView: NSViewRepresentable {
    func makeNSView(context: Context) -> WKWebView {
        WebViewCache.shared.webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        private let pageZoomObserver: Defaults.Observation
        
        init() {
            pageZoomObserver = Defaults.observe(.webViewPageZoom) { change in
                WebViewCache.shared.webView.pageZoom = change.newValue
            }
        }
    }
}
#elseif os(iOS)
struct WebView: UIViewControllerRepresentable {
    let tabID: NSManagedObjectID?

    func makeUIViewController(context: Context) -> WebViewController {
        if let tabID {
            return WebViewController(webView: WebViewCache.shared.getWebView(tabID: tabID))
        } else {
            return WebViewController(webView: WebViewCache.shared.webView)
        }
    }

    func updateUIViewController(_ controller: WebViewController, context: Context) { }
}

class WebViewController: UIViewController {
    private let webView: WKWebView
    private let pageZoomObserver: Defaults.Observation
    private var webViewURLObserver: NSKeyValueObservation?
    private var topSafeAreaConstraint: NSLayoutConstraint?
    private var layoutSubject = PassthroughSubject<Void, Never>()
    private var layoutCancellable: AnyCancellable?
    
    init(webView: WKWebView) {
        self.webView = webView
        self.pageZoomObserver = Defaults.observe(.webViewPageZoom) { change in
            webView.adjustTextSize(pageZoom: change.newValue)
        }
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        webView.alpha = 0
        
        /*
         HACK: Make sure the webview content does not jump after state restoration
         It appears the webview's state restoration does not properly take into account of the content inset.
         To mitigate, first pin the webview's top against safe area top anchor, after all viewDidLayoutSubviews calls,
         pin the webview's top against view's top anchor, so that content does not appears to move up.
         HACK: when view resize, the webview might become zoomed in. To mitigate, set zoom scale to 1.
         */
        NSLayoutConstraint.activate([
            view.leftAnchor.constraint(equalTo: webView.leftAnchor),
            view.bottomAnchor.constraint(equalTo: webView.bottomAnchor),
            view.rightAnchor.constraint(equalTo: webView.rightAnchor),
        ])
        topSafeAreaConstraint = view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: webView.topAnchor)
        topSafeAreaConstraint?.isActive = true
        layoutCancellable = layoutSubject
            .debounce(for: .seconds(0.15), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let view = self?.view,
                      let webView = self?.webView,
                      view.subviews.contains(webView) else { return }
                webView.alpha = 1
                webView.scrollView.zoomScale = 1
                guard self?.topSafeAreaConstraint?.isActive == true else { return }
                self?.topSafeAreaConstraint?.isActive = false
                self?.view.topAnchor.constraint(equalTo: webView.topAnchor).isActive = true
            }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        webView.setValue(view.safeAreaInsets, forKey: "_obscuredInsets")
        layoutSubject.send()
    }
}

extension WKWebView {
    func adjustTextSize(pageZoom: Double? = nil) {
        let pageZoom = pageZoom ?? Defaults[.webViewPageZoom]
        let template = "document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust='%.0f%%'"
        let javascript = String(format: template, pageZoom * 100)
        evaluateJavaScript(javascript, completionHandler: nil)
    }
}
#endif

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
