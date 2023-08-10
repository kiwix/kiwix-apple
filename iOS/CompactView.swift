//
//  CompactView.swift
//  Kiwix
//
//  Created by Chris Li on 7/30/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import SwiftUI

@available(iOS 16.0, *)
struct CompactView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        let controller = CompactViewController(rootView: Content())
        controller.navigationItem.scrollEdgeAppearance = {
            let apperance = UINavigationBarAppearance()
            apperance.configureWithDefaultBackground()
            return apperance
        }()
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.isToolbarHidden = false
        navigationController.toolbar.scrollEdgeAppearance = {
            let apperance = UIToolbarAppearance()
            apperance.configureWithDefaultBackground()
            return apperance
        }()
        return navigationController
    }
    
    func updateUIViewController(_ navigationController: UINavigationController, context: Context) { }
}

private class CompactViewController<Content>: UIHostingController<Content>,
                                              UISearchResultsUpdating, UISearchControllerDelegate where Content: View {
    private let searchController: UISearchController
    private let searchViewModel = SearchViewModel()
    
    override init(rootView: Content) {
        let searchResults = SearchResults().environmentObject(searchViewModel)
        searchController = UISearchController(searchResultsController: UIHostingController(rootView: searchResults))
        super.init(rootView: rootView)
    }
    
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        definesPresentationContext = true

        // configure search
        searchController.delegate = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchResultsUpdater = self
        searchController.showsSearchResultsController = true
        navigationItem.titleView = searchController.searchBar
        
        // observe openURL notification so that search can be deactivated when new article is loaded
        NotificationCenter.default.addObserver(self, selector: #selector(onOpenURL), name: .openURL, object: nil)
    }

    func willPresentSearchController(_ searchController: UISearchController) {
        // The iOS SDK does not add cancel button for an active search bar on iPadOS, so adding one below
        guard traitCollection.horizontalSizeClass == .compact,
              UIDevice.current.userInterfaceIdiom == .pad else { return }
        navigationController?.setToolbarHidden(true, animated: true)
        navigationItem.setRightBarButton(
            UIBarButtonItem(systemItem: .cancel, primaryAction: UIAction { _ in
                searchController.isActive = false
            }), animated: true
        )
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        navigationController?.setToolbarHidden(false, animated: true)
        navigationItem.setRightBarButton(nil, animated: true)
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        guard searchController.isActive else { return }
        searchViewModel.searchText = searchController.searchBar.text ?? ""
    }
        
    @objc func onOpenURL() {
        searchController.isActive = false
    }
}

@available(iOS 16.0, *)
private struct Content: View {
    @EnvironmentObject private var navigation: NavigationViewModel
    @StateObject private var browser = BrowserViewModel()
    
    var body: some View {
        Group {
            if case let .tab(tabID) = navigation.currentItem, browser.url != nil {
                WebView(tabID: tabID).ignoresSafeArea().id(tabID)
            } else {
                List { Text("Welcome") }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                NavigationButtons()
                Spacer()
                OutlineButton()
                Spacer()
                BookmarkButton()
                Spacer()
                RandomArticleButton()
                Spacer()
                TabsManagerButton()
            }
        }
        .environmentObject(browser)
        .onAppear {
            guard case let .tab(tabID) = navigation.currentItem else { return }
            navigation.updateTab(tabID: tabID, lastOpened: Date())
            browser.configure(tabID: tabID, webView: navigation.getWebView(tabID: tabID))
        }
        .onChange(of: navigation.currentItem) { navigationItem in
            guard case let .tab(tabID) = navigation.currentItem else { return }
            navigation.updateTab(tabID: tabID, lastOpened: Date())
            browser.configure(tabID: tabID, webView: navigation.getWebView(tabID: tabID))
        }
    }
}
