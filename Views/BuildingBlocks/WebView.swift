// This file is part of Kiwix for iOS & macOS.
//
// Kiwix is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// any later version.
//
// Kiwix is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Kiwix; If not, see https://www.gnu.org/licenses/.

import Combine
import CoreData
import SwiftUI
import WebKit
import Defaults

#if os(macOS)
struct WebView: NSViewRepresentable {
    @EnvironmentObject private var browser: BrowserViewModel

    func makeNSView(context: Context) -> NSView {
        let nsView = NSView()
        nsView.translatesAutoresizingMaskIntoConstraints = false
        browser.webView.translatesAutoresizingMaskIntoConstraints = false
        nsView.addSubview(browser.webView)
        NSLayoutConstraint.activate([
            browser.webView.leadingAnchor.constraint(equalTo: nsView.leadingAnchor),
            browser.webView.trailingAnchor.constraint(equalTo: nsView.trailingAnchor),
            browser.webView.topAnchor.constraint(equalTo: nsView.topAnchor),
            browser.webView.bottomAnchor.constraint(equalTo: nsView.bottomAnchor)
        ])
        return nsView
    }

    func updateNSView(_ nsView: NSView, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(view: self)
    }

    class Coordinator {
        private let pageZoomObserver: Defaults.Observation

        init(view: WebView) {
            pageZoomObserver = Defaults.observe(.webViewPageZoom) { change in
                view.browser.webView.pageZoom = change.newValue
            }
        }
    }
}
#elseif os(iOS)
struct WebView: UIViewControllerRepresentable {
    @EnvironmentObject private var browser: BrowserViewModel

    func makeUIViewController(context: Context) -> WebViewController {
        WebViewController(webView: browser.webView)
    }

    func updateUIViewController(_ controller: WebViewController, context: Context) { }
}

final class WebViewController: UIViewController {
    private let webView: WKWebView
    private let pageZoomObserver: Defaults.Observation
    private var webViewURLObserver: NSKeyValueObservation?
    private var lastOffset: CGFloat = 0.0
    private var topConstraint: NSLayoutConstraint?
    private var bottomConstraint: NSLayoutConstraint?
    private var urlObserver: NSKeyValueObservation?
    private var animStart: Double = 0

    init(webView: WKWebView) {
        self.webView = webView
        pageZoomObserver = Defaults.observe(.webViewPageZoom) { change in
            webView.adjustTextSize(pageZoom: change.newValue)
        }
        super.init(nibName: nil, bundle: nil)
        webView.scrollView.delegate = self
        urlObserver = webView.observe(\.url, options: [.initial, .new]) { [weak self] _, _ in
            self?.showBars()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        webView.setValue(view.safeAreaInsets, forKey: "_obscuredInsets")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        if Device.current == .iPad {
            topConstraint = webView.topAnchor.constraint(equalTo: view.topAnchor)
            bottomConstraint = webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        }
        NSLayoutConstraint.activate([
            view.leftAnchor.constraint(equalTo: webView.leftAnchor),
            view.rightAnchor.constraint(equalTo: webView.rightAnchor),
            topConstraint,
            bottomConstraint
        ].compactMap { $0 })
    }

    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        showBars()
    }
}

// MARK: - UIScrollViewDelegate
extension WebViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        lastOffset = scrollView.contentOffset.y
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.isDragging {
            let isScrollingDown: Bool = scrollView.contentOffset.y > lastOffset
            if isScrollingDown {
                hideBars()
            } else {
                showBars()
            }
        }
    }

    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        showBars()
    }
}

// MARK: - Toggle bars
extension WebViewController {
    private func hideBars() {
        guard Device.current == .iPhone else { return }
        guard (CACurrentMediaTime() - animStart) > UINavigationController.hideShowBarDuration else {
            return
        }
        animStart = CACurrentMediaTime()
        topConstraint?.isActive = false
        bottomConstraint?.isActive = false
        topConstraint = webView.topAnchor.constraint(equalTo: view.topAnchor)
        bottomConstraint = webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        topConstraint?.isActive = true
        bottomConstraint?.isActive = true
        parent?.navigationController?.setNavigationBarHidden(true, animated: true)
        parent?.navigationController?.setToolbarHidden(true, animated: true)
    }

    func showBars() {
        guard Device.current == .iPhone else { return }
        guard (CACurrentMediaTime() - animStart) > UINavigationController.hideShowBarDuration else {
            return
        }
        animStart = CACurrentMediaTime()
        topConstraint?.isActive = false
        bottomConstraint?.isActive = false
        topConstraint = webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        bottomConstraint = webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        topConstraint?.isActive = true
        bottomConstraint?.isActive = true
        parent?.navigationController?.setNavigationBarHidden(false, animated: true)
        parent?.navigationController?.setToolbarHidden(false, animated: true)
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

final class WebViewConfiguration: WKWebViewConfiguration {
    override init() {
        super.init()
        setURLSchemeHandler(KiwixURLSchemeHandler(), forURLScheme: KiwixURLSchemeHandler.KiwixScheme)
        #if os(macOS)
        preferences.isElementFullscreenEnabled = true
        #endif
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
