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
    @EnvironmentObject private var viewModel: BrowserViewModel
    
    func makeNSView(context: Context) -> WKWebView {
        viewModel.webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) { }
}
#elseif os(iOS)
struct WebView: UIViewControllerRepresentable {
    @EnvironmentObject private var navigation: NavigationViewModel
    
    let tabID: NSManagedObjectID?
        
    func makeUIViewController(context: Context) -> WebViewController {
        if let tabID {
            return WebViewController(webView: navigation.getWebView(tabID: tabID))
        } else {
            return WebViewController(webView: navigation.webView)
        }
    }
    
    func updateUIViewController(_ controller: WebViewController, context: Context) { }
}

class WebViewController: UIViewController {
    private let webView: WKWebView
    private var topSafeAreaConstraint: NSLayoutConstraint?
    private let layoutSubject = PassthroughSubject<Void, Never>()
    private var layoutCancellable: AnyCancellable?
    private var zoomScale: CGFloat = 1
    
    init(webView: WKWebView) {
        self.webView = webView
        super.init(nibName: nil, bundle: nil)
        
        /*
         HACK: when scene enters background, the system resizes the scene and take various screenshots
         (for app switcher), during the resizing the webview might become zoomed in. To mitigate,
         store and reapply webview's zoom scale when scene enters backgroud / foreground.
         */
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sceneDidEnterBackground),
            name: UIScene.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sceneWillEnterForeground),
            name: UIScene.willEnterForegroundNotification,
            object: nil
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        
        /*
         HACK: Make sure the webview content does not jump after state restoration
         It appears the webview's state restoration does not properly take into account of the content inset.
         To mitigate, first pin the webview's top against safe area top anchor, after all viewDidLayoutSubviews calls,
         pin the webview's top against view's top anchor, so that content does not appears to move up.
         */
        NSLayoutConstraint.activate([
            view.leftAnchor.constraint(equalTo: webView.leftAnchor),
            view.bottomAnchor.constraint(equalTo: webView.bottomAnchor),
            view.rightAnchor.constraint(equalTo: webView.rightAnchor),
        ])
        topSafeAreaConstraint = view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: webView.topAnchor)
        topSafeAreaConstraint?.isActive = true
        layoutCancellable = layoutSubject.debounce(for: .seconds(0.1), scheduler: RunLoop.main).sink { _ in
            guard self.view.subviews.contains(self.webView) else { return }
            self.topSafeAreaConstraint?.isActive = false
            let topConstraint = self.view.topAnchor.constraint(equalTo: self.webView.topAnchor)
            topConstraint.isActive = true
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        webView.setValue(view.safeAreaInsets, forKey: "_obscuredInsets")
        layoutSubject.send()
    }
    
    /// Store page zoom scale when scene enters background
    @objc private func sceneDidEnterBackground() {
        zoomScale = webView.scrollView.zoomScale
    }

    /// Reapply stored zoom scale when scene enters foreground
    @objc private func sceneWillEnterForeground() {
        webView.alpha = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.webView.scrollView.setZoomScale(self.zoomScale, animated: false)
            UIView.animate(withDuration: 0.1) {
                self.webView.alpha = 1
            }
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
