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
import CoreData

/// This is macOS and iPad only specific, not used on iPhone
struct BrowserTab: View {
    @ObservedObject var browser: BrowserViewModel
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var library: LibraryViewModel
    @StateObject private var search = SearchViewModel.shared
    
    init(tabID: NSManagedObjectID) {
        self.browser = BrowserViewModel.getCached(tabID: tabID)
    }

    var body: some View {
        let model = if FeatureFlags.hasLibrary {
            CatalogLaunchViewModel(library: library, browser: browser)
        } else {
            NoCatalogLaunchViewModel(browser: browser)
        }
        Content(browser: browser, model: model).toolbar {
#if os(macOS)
            ToolbarItemGroup(placement: .navigation) {
                NavigationButtons(
                    goBack: { [weak browser] in
                        browser?.webView.goBack()
                    },
                    goForward: { [weak browser] in
                        browser?.webView.goForward()
                    })
            }
#elseif os(iOS)
            ToolbarItemGroup(placement: .navigationBarLeading) {
                if #unavailable(iOS 16) {
                    Button {
                        NotificationCenter.toggleSidebar()
                    } label: {
                        Label(LocalString.browser_tab_toolbar_show_sidebar_label, systemImage: "sidebar.left")
                    }
                }
                NavigationButtons(
                    goBack: { [weak browser] in
                        browser?.webView.goBack()
                    },
                    goForward: { [weak browser] in
                        browser?.webView.goForward()
                    })
            }
#endif
            ToolbarItemGroup(placement: .primaryAction) {
                if !Brand.hideTOCButton {
                    OutlineButton(browser: browser)
                }
#if os(iOS)
                if !Brand.hideShareButton {
                    ExportButton(
                        webViewURL: browser.webView.url,
                        pageDataWithExtension: { [weak browser] in await browser?.pageDataWithExtension() },
                        isButtonDisabled: browser.zimFileName.isEmpty
                    )
                }
#else
                if !Brand.hideShareButton {
                    Menu {
                        ExportButton(
                            relativeToView: browser.webView,
                            webViewURL: browser.webView.url,
                            pageDataWithExtension: { [weak browser] in await browser?.pageDataWithExtension() },
                            isButtonDisabled: browser.zimFileName.isEmpty,
                            buttonLabel: LocalString.common_button_share_as_pdf
                        )
                        if let url = browser.webView.url {
                            CopyPasteMenu(url: url)
                                .keyboardShortcut("c", modifiers: [.command, .shift])
                        }
                    } label: {
                        Label(LocalString.common_button_share, systemImage: "square.and.arrow.up")
                    }.disabled(browser.webView.url == nil)
                }
                if !Brand.hidePrintButton {
                    PrintButton(browserURLName: { [weak browser] in
                        browser?.url?.lastPathComponent
                    }, browserDataAsPDF: { [weak browser] in
                        try await browser?.webView.pdf()
                    })
                }
#endif
                TextToSpeechButton(isButtonDisabled: browser.zimFileName.isEmpty) { [weak browser] in
                    browser?.bodyTextAndLanguage(onComplete: { bodyText, langCode in
                        if let bodyText {
                            TextToSpeech.shared.start(for: bodyText, languageCode: langCode)
                        }
                    })
                }
                
                BookmarkButton(articleBookmarked: browser.articleBookmarked,
                               isButtonDisabled: browser.zimFileName.isEmpty,
                               createBookmark: { [weak browser] in browser?.createBookmark() },
                               deleteBookmark: { [weak browser] in browser?.deleteBookmark() })
#if os(iOS)
                if !Brand.hideFindInPage {
                    ContentSearchButton(browser: browser)
                }
#endif
                ArticleShortcutButtons(
                    loadMainArticle: { [weak browser] zimFileID in
                        browser?.loadMainArticle(zimFileID: zimFileID)
                    },
                    loadRandomArticle: { [weak browser] zimFileID in
                        browser?.loadRandomArticle(zimFileID: zimFileID)
                    })
            }
        }
        .environmentObject(search)
        .focusedSceneValue(\.isBrowserURLSet, browser.url != nil)
        #if os(macOS)
        .focusedSceneValue(\.browserURL, browser.url)
        #endif
        .focusedSceneValue(\.canGoBack, browser.canGoBack)
        .focusedSceneValue(\.canGoForward, browser.canGoForward)
        .modifier(ExternalLinkHandler(externalURL: $browser.externalURL))
        .searchable(text: $search.searchText, placement: .toolbar, prompt: LocalString.common_search)
        .onChange(of: scenePhase) { [weak browser] newValue in
            if case .active = newValue {
                browser?.refreshVideoState()
            }
        }
        .modify { [weak browser] view in
#if os(macOS)
            if let browser {
                view.navigationTitle(browser.articleTitle.isEmpty ? Brand.appName : browser.articleTitle)
                    .navigationSubtitle(browser.zimFileName)
            } else {
                view
            }
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
        let browser: BrowserViewModel
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
                        case .loadingData, .webPage:
                            ZStack {
                                LoadingDataView()
                                    .opacity(model.state == .loadingData ? 1.0 : 0.0)
                                WebView(browser: browser)
                                    .opacity(model.state == .loadingData ? 0.0 : 1.0)
                                    .ignoresSafeArea()
                                    .overlay {
                                        if case .webPage(let isLoading) = model.state, isLoading {
                                            LoadingProgressView()
                                        }
                                    }
#if os(macOS)
                                    .overlay(alignment: .bottomTrailing) {
                                        if !Brand.hideFindInPage {
                                            ContentSearchBar(
                                                model: ContentSearchViewModel(
                                                    findInWebPage: browser.webView.find(_:configuration:)
                                                )
                                            )
                                        }
                                    }
#endif
                            }
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
