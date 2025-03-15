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

import SwiftUI
import Defaults
import WebKit
import CoreData

/// This is macOS and iPad only specific, not used on iPhone
struct BrowserTab: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var library: LibraryViewModel
    @StateObject private var search = SearchViewModel.shared
    @ObservedObject private var browser: BrowserViewModel
    private var model: LaunchViewModelBase {
        if FeatureFlags.hasLibrary {
            CatalogLaunchViewModel(library: library, browser: browser)
        } else {
            NoCatalogLaunchViewModel(browser: browser)
        }
    }
    
    init(currentTabID: NSManagedObjectID) {
        browser = BrowserViewModel.getCached(tabID: currentTabID)
    }

    var body: some View {
        Content(browser: browser, model: model).toolbar {
#if os(macOS)
            ToolbarItemGroup(placement: .navigation) { NavigationButtons(currentTabId: browser.tabID) }
#elseif os(iOS)
            ToolbarItemGroup(placement: .navigationBarLeading) {
                if #unavailable(iOS 16) {
                    Button {
                        NotificationCenter.toggleSidebar()
                    } label: {
                        Label(LocalString.browser_tab_toolbar_show_sidebar_label, systemImage: "sidebar.left")
                    }
                }
                NavigationButtons(currentTabId: browser.tabID)
            }
#endif
            ToolbarItemGroup(placement: .primaryAction) {
                OutlineButton(browser: browser)
                ExportButton(browser: browser)
#if os(macOS)
                PrintButton(browser: browser)
#endif
                BookmarkButton(browser: browser)
#if os(iOS)
                ContentSearchButton(browser: browser)
#endif
                ArticleShortcutButtons(browser: browser, displayMode: .mainAndRandomArticle)
            }
        }
        .environmentObject(search)
        .focusedSceneValue(\.canGoBack, browser.canGoBack)
        .focusedSceneValue(\.canGoForward, browser.canGoForward)
        .modifier(ExternalLinkHandler(externalURL: $browser.externalURL))
        .searchable(text: $search.searchText, placement: .toolbar, prompt: LocalString.common_search)
        .onChange(of: scenePhase) { [weak browser] newValue in
            if case .active = newValue {
                browser?.refreshVideoState()
            }
        }
        .modify { view in
#if os(macOS)
            view.navigationTitle(browser.articleTitle.isEmpty ? Brand.appName : browser.articleTitle)
                .navigationSubtitle(browser.zimFileName)
#elseif os(iOS)
            view
#endif
        }
        .onAppear { [weak browser] in
            browser?.updateLastOpened()
        }
        .onDisappear { [weak browser] in
            browser?.pauseVideoWhenNotInPIP()
            browser?.persistState()
        }
    }

    private struct Content<LaunchModel>: View where LaunchModel: LaunchProtocol {
        @Environment(\.isSearching) private var isSearching
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        @ObservedObject var browser: BrowserViewModel
        @EnvironmentObject private var library: LibraryViewModel
        @EnvironmentObject private var navigation: NavigationViewModel
        @FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
            predicate: ZimFile.openedPredicate
        ) private var zimFiles: FetchedResults<ZimFile>
        /// this is still hacky a bit, as the change from here re-validates the view
        /// which triggers the model to be revalidated
        @Default(.hasSeenCategories) private var hasSeenCategories
        @ObservedObject var model: LaunchModel

        var body: some View {
            // swiftlint:disable:next redundant_discardable_let
            let _ = model.updateWith(hasZimFiles: !zimFiles.isEmpty,
                             hasSeenCategories: hasSeenCategories)
            GeometryReader { proxy in
                Group {
                    if isSearching {
                        SearchResults()
                            #if os(macOS)
                            .environment(\.horizontalSizeClass, proxy.size.width > 650 ? .regular : .compact)
                            #elseif os(iOS)
                            .environment(\.horizontalSizeClass, proxy.size.width > 750 ? .regular : .compact)
                            #endif
                    } else {
                        switch model.state {
                        case .loadingData:
                            LoadingDataView()
                        case .webPage(let isLoading):
                            WebView(browser: browser)
                                .ignoresSafeArea()
                                .overlay {
                                    if isLoading {
                                        LoadingProgressView()
                                    }
                                }
#if os(macOS)
                                .overlay(alignment: .bottomTrailing) { [weak browser] in
                                    ContentSearchBar(
                                        model: ContentSearchViewModel(
                                            findInWebPage: browser?.webView.find(_:configuration:)
                                        )
                                    )
                                }
#endif
                        case .catalog(.fetching):
                            FetchingCatalogView()
                        case .catalog(.list):
                            LocalLibraryList(browser: browser)
                        case .catalog(.welcome(let welcomeViewState)):
                            WelcomeCatalog(viewState: welcomeViewState)
                        }
                    }
                }
            }
            .onChange(of: library.state) { state in
                guard state == .complete else { return }
                showTheLibrary()
            }
        }

        private func showTheLibrary() {
            guard model.state.shouldShowCatalog else { return }
            navigation.currentItem = .categories
        }
    }
}
