//
//  Reader.swift
//  Kiwix
//
//  Created by Chris Li on 10/19/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import CoreData
import SwiftUI
import UniformTypeIdentifiers
import WebKit

struct Reader: View {
    @StateObject var viewModel = ReaderViewModel()
    @State var url: URL?
    @FetchRequest(sortDescriptors: []) private var onDeviceZimFiles: FetchedResults<ZimFile>
    
    var body: some View {
        NavigationView {
            Sidebar(url: $url)
                .frame(minWidth: 250)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button { Kiwix.toggleSidebar() } label: { Image(systemName: "sidebar.leading") }
                    }
                }
            WebView(url: $url, webView: viewModel.webView)
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
                        }
                        .disabled(onDeviceZimFiles.isEmpty)
                        Menu {
                            ForEach(onDeviceZimFiles) { zimFile in
                                Button(zimFile.name) { viewModel.loadRandomPage(zimFileID: zimFile.id) }
                            }
                        } label: {
                            Label("Random Page", systemImage: "die.face.5")
                        } primaryAction: {
                            guard let zimFile = onDeviceZimFiles.first else { return }
                            viewModel.loadRandomPage(zimFileID: zimFile.fileID)
                        }.disabled(onDeviceZimFiles.isEmpty)
                    }
                }
        }
        .environmentObject(viewModel)
        .focusedSceneValue(\.readerViewModel, viewModel)
        .navigationTitle(viewModel.articleTitle)
        .navigationSubtitle(viewModel.zimFileName)
    }
}

class ReaderViewModel: NSObject, ObservableObject, WKNavigationDelegate, WKScriptMessageHandler {
    @Published private(set) var canGoBack: Bool = false
    @Published private(set) var canGoForward: Bool = false
    @Published private(set) var articleTitle: String = ""
    @Published private(set) var zimFileName: String = ""
    
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
                  let zimFile = try? Database.shared.container.viewContext.fetch(
                    ZimFile.fetchRequest(predicate: NSPredicate(format: "fileID == %@", zimFileID))
                  ).first else { return }
            self.articleTitle = title
            self.zimFileName = zimFile.name
        }
        
        webView.configuration.userContentController.add(self, name: "headingVisible")
    }
    
    func loadMainPage(zimFileID: UUID? = nil) {
        let zimFileID = zimFileID?.uuidString ?? webView.url?.host ?? ""
        guard let url = ZimFileService.shared.getMainPageURL(zimFileID: zimFileID) else { return }
        webView.load(URLRequest(url: url))
    }
    
    func loadRandomPage(zimFileID: UUID? = nil) {
        let zimFileID = zimFileID?.uuidString ?? webView.url?.host ?? ""
        guard let url = ZimFileService.shared.getRandomPageURL(zimFileID: zimFileID) else { return }
        webView.load(URLRequest(url: url))
    }
    
    func navigate(outlineItemIndex: Int) {
        let javascript = "document.querySelectorAll(\"h1, h2, h3, h4, h5, h6\")[\(outlineItemIndex)].scrollIntoView()"
        webView.evaluateJavaScript(javascript)
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        guard let url = navigationAction.request.url else { return .cancel }
        if url.isKiwixURL, let redirectedURL = ZimFileService.shared.getRedirectedURL(url: url) {
            DispatchQueue.main.async { webView.load(URLRequest(url: redirectedURL)) }
            return .cancel
        } else if url.isKiwixURL {
            return .allow
        } else if url.scheme == "http" || url.scheme == "https" {
            DispatchQueue.main.async { NSWorkspace.shared.open(url) }
            return .cancel
        } else if url.scheme == "geo" {
            let coordinate = url.absoluteString.replacingOccurrences(of: "geo:", with: "")
            if let url = URL(string: "http://maps.apple.com/?ll=\(coordinate)") {
                DispatchQueue.main.async { NSWorkspace.shared.open(url) }
            }
            return .cancel
        } else {
            return .cancel
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let javascript = """
        // expand all detail tags
        document.querySelectorAll('details').forEach( detail => {
            detail.setAttribute('open', true)
        })

        // generate id for all heading if there isn't one already
        var headings = document.querySelectorAll('h1, h2, h3, h4, h5, h6')
        headings.forEach( (heading, index) => {
            if (!heading.id) {
                let parts = heading.textContent.trim().split(' ').concat([index])
                heading.id = parts.join('_')
            }
        })

        // retrieve all heading elements as objects
        Array.from(headings).map( heading => {
            return {
                id: heading.id,
                text: heading.textContent.trim(),
                tag: heading.tagName,
            }
        })
        """
        webView.evaluateJavaScript(javascript) { result, error in
            guard let result = result as? [[String: String]] else { return }
            print(result)
        }
    }
    
    // MARK: - WKScriptMessageHandler
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print(message.body as? [String: String] ?? [:])
    }
}
