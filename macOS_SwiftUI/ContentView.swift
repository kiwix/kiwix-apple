//
//  ContentView.swift
//  Kiwix
//
//  Created by Chris Li on 10/19/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import CoreData
import SwiftUI
import UniformTypeIdentifiers
import WebKit

struct ContentView: View {
    @StateObject var viewModel = SceneViewModel()
    @State var url: URL?
    @State var isPresentingFileImporter: Bool = false
    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest(sortDescriptors: []) private var onDeviceZimFiles: FetchedResults<ZimFile>
    
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
                        }
                        .disabled(onDeviceZimFiles.isEmpty)
                        Menu {
                            ForEach(onDeviceZimFiles) { zimFile in
                                Button(zimFile.name) { viewModel.loadRandomPage(zimFileID: zimFile.id.uuidString) }
                            }
                        } label: {
                            Label("Random Page", systemImage: "die.face.5")
                        } primaryAction: {
                            guard let zimFile = onDeviceZimFiles.first else { return }
                            viewModel.loadRandomPage(zimFileID: zimFile.fileID.uuidString)
                        }.disabled(onDeviceZimFiles.isEmpty)
                    }
                }
        }
        .environmentObject(viewModel)
        .focusedSceneValue(\.fileImporter, $isPresentingFileImporter)
        .focusedSceneValue(\.sceneViewModel, viewModel)
        .navigationTitle(viewModel.articleTitle)
        .navigationSubtitle(viewModel.zimFileTitle)
        .fileImporter(isPresented: $isPresentingFileImporter, allowedContentTypes: [UTType(exportedAs: "org.openzim.zim")]) { result in
            if case let .success(url) = result {
                guard let metadata = ZimFileService.getMetaData(url: url) else { return }
                ZimFileService.shared.open(url: url)
                let zimFile = ZimFile(context: managedObjectContext)
                zimFile.fileID = UUID(uuidString: metadata.identifier)!
                zimFile.name = metadata.title
                zimFile.mainPage = ZimFileService.shared.getMainPageURL(zimFileID: metadata.identifier)!
                zimFile.fileURLBookmark = ZimFileService.shared.getFileURLBookmark(zimFileID: metadata.identifier)
                try? managedObjectContext.save()
            }
        }
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
//        titleObserver = webView.observe(\.title) { [unowned self] webView, _ in
//            guard let title = webView.title, !title.isEmpty,
//                  let zimFileID = webView.url?.host,
//                  let zimFile = (try? Realm())?.object(ofType: ZimFile.self, forPrimaryKey: zimFileID) else { return }
//            self.articleTitle = title
//            self.zimFileTitle = zimFile.title
//        }
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
