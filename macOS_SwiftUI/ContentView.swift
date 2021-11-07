//
//  ContentView.swift
//  Kiwix
//
//  Created by Chris Li on 10/19/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI
import WebKit
import RealmSwift

struct ContentView: View {
    @StateObject var viewModel = SceneViewModel()
    
    var body: some View {
        NavigationView {
            Sidebar()
                .frame(minWidth: 250)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button { toggleSidebar() } label: { Image(systemName: "sidebar.leading") }
                    }
                }
            WebView()
                .ignoresSafeArea(.container, edges: .vertical)
                .frame(idealWidth: 800, minHeight: 300, idealHeight: 350)
                .toolbar {
                    ToolbarItemGroup(placement: .navigation) {
                        Button { viewModel.action = .back } label: {
                            Image(systemName: "chevron.backward")
                        }.disabled(!viewModel.canGoBack)
                        Button { viewModel.action = .forward } label: {
                            Image(systemName: "chevron.forward")
                        }.disabled(!viewModel.canGoForward)
                    }
                    ToolbarItemGroup {
                        Button { viewModel.loadMainPage() } label: { Image(systemName: "house") }
                        Button { viewModel.loadRandomPage() } label: { Image(systemName: "die.face.5") }
                    }
                }
        }
        .environmentObject(viewModel)
        .navigationTitle(viewModel.articleTitle)
        .navigationSubtitle(viewModel.zimFileTitle)
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}

class SceneViewModel: NSObject, ObservableObject, WKNavigationDelegate {
    @Published var action: WebViewAction?
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var url: URL?
    @Published var articleTitle: String = ""
    @Published var zimFileTitle: String = ""
    
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
            return controller
        }()
        return WKWebView(frame: .zero, configuration: config)
    }()
    var canGoBackObserver: NSKeyValueObservation?
    var canGoForwardObserver: NSKeyValueObservation?
    var urlObserver: NSKeyValueObservation?
    
    override init() {
        super.init()
        webView.navigationDelegate = self
        canGoBackObserver = webView.observe(\.canGoBack) { [unowned self] webView, _ in
            self.canGoBack = webView.canGoBack
        }
        canGoForwardObserver = webView.observe(\.canGoForward) { [unowned self] webView, _ in
            self.canGoForward = webView.canGoForward
        }
        urlObserver = webView.observe(\.url) { webView, _ in
            self.url = webView.url
            if let title = webView.title,
               let database = try? Realm(),
               let zimFileID = webView.url?.host,
               let zimFile = database.object(ofType: ZimFile.self, forPrimaryKey: zimFileID),
               !title.isEmpty {
                self.articleTitle = title
                self.zimFileTitle = zimFile.title
            } else {
                self.articleTitle = ""
                self.zimFileTitle = ""
            }
        }
    }
    
    func loadMainPage(zimFileID: String? = nil) {
        let zimFileID = zimFileID ?? webView.url?.host ?? ""
        guard let url = ZimFileService.shared.getMainPageURL(zimFileID: zimFileID) else { return }
        webView.load(URLRequest(url: url))
    }
    
    func loadRandomPage(zimFileID: String? = nil) {
        let zimFileID = zimFileID ?? webView.url?.host ?? ""
        guard let url = ZimFileService.shared.getRandomPageURL(zimFileID: zimFileID) else { return }
        webView.load(URLRequest(url: url))
    }
}
