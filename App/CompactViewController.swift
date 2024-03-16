//
//  CompactViewController.swift
//  Kiwix
//
//  Created by Chris Li on 9/4/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

#if os(iOS)
import Combine
import SwiftUI
import UIKit
import SwiftBackports

final class CompactViewController: UIHostingController<AnyView>, UISearchControllerDelegate, UISearchResultsUpdating {

    private enum Const {
        #if os(macOS)
        static let randomButtonTitle: String = "article_shortcut.random.button.title.mac".localized
        #else
        static let randomButtonTitle: String = "article_shortcut.random.button.title.ios".localized
        #endif
    }
    private let searchViewModel: SearchViewModel
    private let searchController: UISearchController
    private var searchTextObserver: AnyCancellable?
    private var openURLObserver: NSObjectProtocol?
    private var loadRandomArticle: (() -> Void)?
    init() {
        searchViewModel = SearchViewModel()
        let searchResult = SearchResults().environmentObject(searchViewModel)
        searchController = UISearchController(searchResultsController: UIHostingController(rootView: searchResult))
        let compactView = CompactView()
        loadRandomArticle = compactView.loadRandomArticle
        super.init(rootView: AnyView(compactView))
        searchController.searchResultsUpdater = self
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        definesPresentationContext = true
        navigationController?.isToolbarHidden = false
        navigationController?.toolbar.scrollEdgeAppearance = {
            let apperance = UIToolbarAppearance()
            apperance.configureWithDefaultBackground()
            return apperance
        }()
        navigationItem.scrollEdgeAppearance = {
            let apperance = UINavigationBarAppearance()
            apperance.configureWithDefaultBackground()
            return apperance
        }()
        searchController.searchBar.autocorrectionType = .no
        navigationItem.titleView = searchController.searchBar
        navigationItem.rightBarButtonItem = randomArticleButton()
        searchController.automaticallyShowsCancelButton = false
        searchController.delegate = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.showsSearchResultsController = true
        searchController.searchBar.searchTextField.placeholder = "common.search".localized

        searchTextObserver = searchViewModel.$searchText.sink { [weak self] searchText in
            guard self?.searchController.searchBar.text != searchText else { return }
            self?.searchController.searchBar.text = searchText
        }
        openURLObserver = NotificationCenter.default.addObserver(
            forName: .openURL, object: nil, queue: nil
        ) { [weak self] _ in
            self?.searchController.isActive = false
            self?.navigationItem.setRightBarButton(self?.randomArticleButton(), animated: true)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func willPresentSearchController(_ searchController: UISearchController) {
        navigationController?.setToolbarHidden(true, animated: true)
        navigationItem.setRightBarButton(
            UIBarButtonItem(
                title: "common.button.cancel".localized,
                style: .done,
                target: self,
                action: #selector(onSearchCancelled)
            ),
            animated: true
        )
    }
    @objc func onSearchCancelled() {
        searchController.isActive = false
        navigationItem.setRightBarButton(randomArticleButton(), animated: true)
    }

    @objc func onRandomTapped(_ target: UIButton) {
        loadRandomArticle?()
    }

    private func randomArticleButton() -> UIBarButtonItem {
        UIBarButtonItem(image: .init(systemName: "die.face.5"),
                        style: .plain,
                        target: self,
                        action: #selector(onRandomTapped))
    }

    func willDismissSearchController(_ searchController: UISearchController) {
        navigationController?.setToolbarHidden(false, animated: true)
        searchViewModel.searchText = ""
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        searchViewModel.searchText = searchController.searchBar.text ?? ""
    }
}

private struct CompactView: View {
    @EnvironmentObject private var navigation: NavigationViewModel

    func loadRandomArticle() {
        if case let .tab(tabID) = navigation.currentItem {
            BrowserViewModel(tabID: tabID).loadRandomArticle()
        }
    }

    init() {
        debugPrint("Create CompactView")
    }

    var body: some View {
        if case let .tab(tabID) = navigation.currentItem {
            Content().id(tabID).toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    HStack {
                        NavigationButtons()
                        Spacer()
                        OutlineButton()
                        Spacer()
                        BookmarkButton()
                        Spacer()
                        TabsManagerButton()
//                        Spacer()
//                        ArticleShortcutButtons(displayMode: .randomArticle)
                        if FeatureFlags.hasLibrary {
                            Spacer()
                            Button {
//                                presentedSheet = .library
                            } label: {
                                Label("common.tab.menu.library".localized, systemImage: "folder")
                            }
                        }
                        Spacer()
                        Button {
//                            presentedSheet = .settings
                        } label: {
                            Label("common.tab.menu.settings".localized, systemImage: "gear")
                        }
                    }
                }
            }
            .environmentObject(BrowserViewModel.getCached(tabID: tabID))
        }
    }
}

private struct Content: View {
    @EnvironmentObject private var browser: BrowserViewModel

    var body: some View {
        Group {
            if browser.url == nil {
                Welcome()
            } else {
                WebView().ignoresSafeArea()
            }
        }
        .focusedSceneValue(\.browserViewModel, browser)
        .focusedSceneValue(\.canGoBack, browser.canGoBack)
        .focusedSceneValue(\.canGoForward, browser.canGoForward)
        .modifier(ExternalLinkHandler(externalURL: $browser.externalURL))
        .onAppear {
            browser.updateLastOpened()
        }
        .onDisappear {
            browser.persistState()
        }
    }
}
#endif
