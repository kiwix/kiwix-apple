//
//  WebView.swift
//  macOS_SwiftUI
//
//  Created by Chris Li on 11/5/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI
import WebKit
import RealmSwift

struct WebView: NSViewRepresentable {
    @EnvironmentObject var viewModel: SceneViewModel
    
    func makeNSView(context: Context) -> WKWebView {
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
            return controller
        }()        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        guard let action = viewModel.action else { return }
        defer { viewModel.action = nil }
        switch action {
        case .back:
            nsView.goBack()
        case .forward:
            nsView.goForward()
        case .url(let url):
            nsView.load(URLRequest(url: url))
        case .main(let zimFileID):
            let zimFileID = zimFileID ?? nsView.url?.host ?? ""
            guard let url = ZimFileService.shared.getMainPageURL(zimFileID: zimFileID) else { return }
            nsView.load(URLRequest(url: url))
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self.viewModel)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let viewModel: SceneViewModel
        
        init(_ viewModel: SceneViewModel) {
            self.viewModel = viewModel
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            viewModel.canGoBack = webView.canGoBack
            viewModel.canGoForward = webView.canGoForward
            viewModel.articleTitle = webView.title
            viewModel.zimFileTitle = {
                guard let zimFileID = webView.url?.host,
                      let database = try? Realm() else { return nil }
                let zimFile = database.object(ofType: ZimFile.self, forPrimaryKey: zimFileID)
                return zimFile?.title
            }()
        }
    }
}

enum WebViewAction {
    case back, forward, url(URL), main(String? = nil)
}
