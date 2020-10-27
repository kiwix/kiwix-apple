//
//  SceneViewModel.swift
//  Kiwix
//
//  Created by Chris Li on 10/24/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import SwiftUI
import WebKit

@available(iOS 14.0, *)
enum ContentDisplayMode {
    case homeView, webView, transitionView
}

@available(iOS 14.0, *)
class SceneViewModel: NSObject, ObservableObject, UISearchBarDelegate, WKNavigationDelegate {
    let searchBar = UISearchBar()
    let webView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(KiwixURLSchemeHandler(), forURLScheme: "kiwix")
        config.mediaTypesRequiringUserActionForPlayback = []
        return WKWebView(frame: .zero, configuration: config)
    }()
    private let searchQueue = SearchQueue()
    
    @Published private(set) var contentDisplayMode = ContentDisplayMode.homeView
    @Published private(set) var isSearchActive = false
    @Published private(set) var searchText = ""
    @Published private(set) var canGoBack = false
    @Published private(set) var canGoForward = false
    @Published private(set) var currentArticleURL: URL?
    
    override init() {
        super.init()
        searchBar.autocorrectionType = .no
        searchBar.autocapitalizationType = .none
        searchBar.delegate = self
        searchBar.placeholder = "Search"
        searchBar.searchBarStyle = .minimal
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
    }
    
    // MARK: - Actions
    
    func goBack() {
        webView.goBack()
    }
    
    func goForward() {
        webView.goForward()
    }
    
    func loadMainPage(zimFile: ZimFile) {
        guard let mainPageURL = ZimMultiReader.shared.getMainPageURL(zimFileID: zimFile.id) else { return }
        if contentDisplayMode == .homeView {
            withAnimation(.easeIn(duration: 0.1)) { contentDisplayMode = .transitionView }
        }
        webView.load(URLRequest(url: mainPageURL))
    }
    
    func houseButtonTapped() {
        withAnimation(Animation.easeInOut(duration: 0.2)) {
            contentDisplayMode = contentDisplayMode == .homeView ? .webView : .homeView
        }
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        withAnimation {
            isSearchActive = true
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
//        searchQueue.cancelAllOperations()
//        let operation = SearchOperation(searchText: searchText, zimFileIDs: Set())
//        operation.completionBlock = { [weak self] in
//            guard !operation.isCancelled else { return }
//            DispatchQueue.main.sync {
//                print("search finished")
//            }
//        }
//        searchQueue.addOperation(operation)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        withAnimation {
            isSearchActive = false
            searchBar.endEditing(true)
            searchBar.text = nil
        }
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if contentDisplayMode == .transitionView {
            withAnimation(.easeOut(duration: 0.1)) { contentDisplayMode = .webView }
        }
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        currentArticleURL = webView.url
    }
}
