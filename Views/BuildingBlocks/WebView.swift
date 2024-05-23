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
import os

#if os(macOS)
struct WebView: NSViewRepresentable {
    @EnvironmentObject private var browser: BrowserViewModel

    func makeNSView(context: Context) -> WKWebView {
        browser.webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) { }

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

class WebViewController: UIViewController {
    private let webView: WKWebView
    private let pageZoomObserver: Defaults.Observation
    private var webViewURLObserver: NSKeyValueObservation?
    private var lastOFfset: CGFloat = 0.0
    
    init(webView: WKWebView) {
        self.webView = webView
        self.pageZoomObserver = Defaults.observe(.webViewPageZoom) { change in
            webView.adjustTextSize(pageZoom: change.newValue)
        }
        super.init(nibName: nil, bundle: nil)
        self.webView.scrollView.delegate = self
        webView.setValue(true, forKey: "_haveSetObscuredInsets")
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
        NSLayoutConstraint.activate([
            view.leftAnchor.constraint(equalTo: webView.leftAnchor),
            view.bottomAnchor.constraint(equalTo: webView.bottomAnchor),
            view.rightAnchor.constraint(equalTo: webView.rightAnchor),
            view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: webView.topAnchor)
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        debugPrint("WebView::viewDidLayoutSubviews")
    }
}

// MARK: - UIScrollViewDelegate
extension WebViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if Device.current == .iPhone {
            lastOFfset = scrollView.contentOffset.y
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if Device.current == .iPhone, scrollView.isDragging {
            let isScrollingDown: Bool = scrollView.contentOffset.y > lastOFfset
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
        view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: webView.topAnchor).isActive = false
        view.topAnchor.constraint(equalTo: webView.topAnchor).isActive = true
        parent?.navigationController?.setNavigationBarHidden(true, animated: true)
        parent?.navigationController?.setToolbarHidden(true, animated: true)
    }

    func showBars() {
        view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: webView.topAnchor).isActive = true
        view.topAnchor.constraint(equalTo: webView.topAnchor).isActive = false
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
        if #available(macOS 12.3, *) {
            preferences.isElementFullscreenEnabled = true
        }
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
