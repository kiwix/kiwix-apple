//
//  ContentView.swift
//  Kiwix
//
//  Created by Chris Li on 10/19/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import CoreData
import SwiftUI
import WebKit
import RealmSwift

struct ContentView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @StateObject var viewModel = SceneViewModel()
    @State var url: URL?
    @ObservedResults(
        ZimFile.self,
        filter: NSPredicate(format: "stateRaw == %@", ZimFile.State.onDevice.rawValue),
        sortDescriptor: SortDescriptor(keyPath: "size", ascending: false)
    ) private var onDevice
    
    /// Used to track if the current article is bookmarked
    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "articleURL == nil")
    ) private var currentArticleBookmarks: FetchedResults<Bookmark>
    
    var body: some View {
        NavigationView {
            Sidebar(url: $url)
                .environmentObject(viewModel)
                .frame(minWidth: 250)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button { toggleSidebar() } label: { Image(systemName: "sidebar.leading") }
                    }
                }
            Group {
                if url == nil {
                    EmptyView()
                } else {
                    WebView(url: $url, webView: viewModel.webView)
                }
            }
                .ignoresSafeArea(.container, edges: .vertical)
                .frame(minWidth: 400, idealWidth: 800, minHeight: 400, idealHeight: 550)
                .toolbar {
                    ToolbarItemGroup(placement: .navigation) {
                        Button { viewModel.webView.goBack() } label: {
                            Image(systemName: "chevron.backward")
                        }.disabled(!viewModel.canGoBack)
                        Button { viewModel.webView.goForward() } label: {
                            Image(systemName: "chevron.forward")
                        }.disabled(!viewModel.canGoForward)
                    }
                    ToolbarItemGroup {
                        BookmarkButton(url: $url)
                        Button {
                            viewModel.loadMainPage()
                        } label: {
                            Image(systemName: "house")
                        }.disabled(onDevice.isEmpty)
                        Menu {
                            ForEach(onDevice) { zimFile in
                                Button(zimFile.title) { viewModel.loadRandomPage(zimFileID: zimFile.fileID) }
                            }
                        } label: {
                            Label("Random Page", systemImage: "die.face.5")
                        } primaryAction: {
                            guard let zimFile = onDevice.first else { return }
                            viewModel.loadRandomPage(zimFileID: zimFile.fileID)
                        }.disabled(onDevice.isEmpty)
                    }
                }
        }
        .onChange(of: url, perform: { url in
            if let url = url {
                currentArticleBookmarks.nsPredicate = NSPredicate(format: "articleURL == %@", url as CVarArg)
            } else {
                currentArticleBookmarks.nsPredicate = NSPredicate(format: "articleURL == nil")
            }
        })
        .environmentObject(viewModel)
        .focusedSceneValue(\.sceneViewModel, viewModel)
        .navigationTitle(viewModel.articleTitle)
        .navigationSubtitle(viewModel.zimFileTitle)
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}

class SceneViewModel: NSObject, ObservableObject, WKNavigationDelegate {
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
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
    private var canGoBackObserver: NSKeyValueObservation?
    private var canGoForwardObserver: NSKeyValueObservation?
    private var titleObserver: NSKeyValueObservation?
    
    override init() {
        super.init()
        webView.navigationDelegate = self
        canGoBackObserver = webView.observe(\.canGoBack) { [unowned self] webView, _ in
            self.canGoBack = webView.canGoBack
        }
        canGoForwardObserver = webView.observe(\.canGoForward) { [unowned self] webView, _ in
            self.canGoForward = webView.canGoForward
        }
        titleObserver = webView.observe(\.title) { [unowned self] webView, _ in
            guard let title = webView.title, !title.isEmpty,
                  let zimFileID = webView.url?.host,
                  let zimFile = (try? Realm())?.object(ofType: ZimFile.self, forPrimaryKey: zimFileID) else { return }
            self.articleTitle = title
            self.zimFileTitle = zimFile.title
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
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { decisionHandler(.cancel); return }
        if url.isKiwixURL, let redirectedURL = ZimFileService.shared.getRedirectedURL(url: url) {
            decisionHandler(.cancel)
            webView.load(URLRequest(url: redirectedURL))
        } else if url.isKiwixURL {
            decisionHandler(.allow)
        } else if url.scheme == "http" || url.scheme == "https" {
            decisionHandler(.cancel)
            NSWorkspace.shared.open(url)
        } else if url.scheme == "geo" {
            decisionHandler(.cancel)
            let coordinate = url.absoluteString.replacingOccurrences(of: "geo:", with: "")
            if let url = URL(string: "http://maps.apple.com/?ll=\(coordinate)") {
                NSWorkspace.shared.open(url)
            }
        } else {
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript(
            "document.querySelectorAll(\"details\").forEach((detail) => {detail.setAttribute(\"open\", true)});",
            completionHandler: nil
        )
    }
}
