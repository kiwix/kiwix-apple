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

/// This is macOS and iPad only specific, not used on iPhone
struct BrowserTab: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var browser: BrowserViewModel
    @EnvironmentObject private var library: LibraryViewModel
    @StateObject private var search = SearchViewModel()
    @FocusState private var searchFocus: Int?

    var body: some View {
        let model = if FeatureFlags.hasLibrary {
            CatalogLaunchViewModel(library: library, browser: browser)
        } else {
            NoCatalogLaunchViewModel(browser: browser)
        }
        Content(model: model, searchFocus: $searchFocus).toolbar {
#if os(macOS)
            ToolbarItemGroup(placement: .navigation) { NavigationButtons() }
#elseif os(iOS)
            ToolbarItemGroup(placement: .navigationBarLeading) {
                if #unavailable(iOS 16) {
                    Button {
                        NotificationCenter.toggleSidebar()
                    } label: {
                        Label("browser_tab.toolbar.show_sidebar.label".localized, systemImage: "sidebar.left")
                    }
                }
                NavigationButtons()
            }
#endif
            ToolbarItemGroup(placement: .primaryAction) {
                OutlineButton()
                ExportButton()
#if os(macOS)
                PrintButton()
#endif
                BookmarkButton()
#if os(iOS)
                ContentSearchButton()
#endif
                ArticleShortcutButtons(displayMode: .mainAndRandomArticle)
                
#if os(macOS)
                Button(action: {
                    searchFocus = searchFocus ?? search.results.first?.id
                }) {}
                    .opacity(0)
                    .keyboardShortcut(.return, modifiers: [])
#endif
            }
        }
        .environmentObject(search)
        .focusedSceneValue(\.browserViewModel, browser)
        .focusedSceneValue(\.canGoBack, browser.canGoBack)
        .focusedSceneValue(\.canGoForward, browser.canGoForward)
        .modifier(ExternalLinkHandler(externalURL: $browser.externalURL))
        .searchable(text: $search.searchText, placement: .toolbar, prompt: "common.search".localized)
        .onChange(of: scenePhase) { newValue in
            if case .active = newValue {
                browser.refreshVideoState()
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
        .onAppear {
            browser.updateLastOpened()
        }
        .onDisappear {
            browser.pauseVideoWhenNotInPIP()
            browser.persistState()
        }
    }

    private struct Content<LaunchModel>: View where LaunchModel: LaunchProtocol {
        @Environment(\.isSearching) private var isSearching
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        @EnvironmentObject private var browser: BrowserViewModel
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
        @FocusState.Binding var searchFocus: Int?

        var body: some View {
            // swiftlint:disable:next redundant_discardable_let
            let _ = model.updateWith(hasZimFiles: !zimFiles.isEmpty,
                             hasSeenCategories: hasSeenCategories)
            GeometryReader { proxy in
                Group {
                    if isSearching {
                        SearchResults(searchFocus: $searchFocus)
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
                            WebView()
                                .ignoresSafeArea()
                                .overlay {
                                    if isLoading {
                                        LoadingProgressView()
                                    }
                                }
#if os(macOS)
                                .overlay(alignment: .bottomTrailing) {
                                    ContentSearchBar(
                                        model: ContentSearchViewModel(
                                            findInWebPage: browser.webView.find(_:configuration:)
                                        )
                                    )
                                }
#endif
                        case .catalog(.fetching):
                            FetchingCatalogView()
                        case .catalog(.list):
                            LocalLibraryList()
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
