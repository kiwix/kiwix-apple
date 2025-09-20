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

//
//  CompactViewController.swift
//  Kiwix

#if os(iOS)
import Combine
import SwiftUI
import UIKit
import CoreData
import Defaults

final class CompactViewController: UIHostingController<AnyView>, UISearchControllerDelegate, UISearchResultsUpdating {
    private let searchViewModel: SearchViewModel
    private let searchController: UISearchController
    private var searchTextObserver: AnyCancellable?
    private var openURLObserver: NSObjectProtocol?

    private var trailingNavItemGroups: [UIBarButtonItemGroup] = []
    private var rightNavItem: UIBarButtonItem?
    private let navigation: NavigationViewModel
    private var navigationItemObserver: AnyCancellable?

    init(navigation: NavigationViewModel) {
        self.navigation = navigation
        searchViewModel = SearchViewModel.shared
        let searchResult = SearchResults().environmentObject(searchViewModel)
        searchController = UISearchController(searchResultsController: UIHostingController(rootView: searchResult))
        super.init(rootView: AnyView(CompactViewWrapper()))
        searchController.searchResultsUpdater = self
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItemObserver = navigation.$currentItem
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] currentItem in
                if currentItem != .loading {
                    self?.navigationController?.isToolbarHidden = false
                    self?.navigationController?.isNavigationBarHidden = false
                    // listen to only the first change from .loading to something else
                    self?.navigationItemObserver?.cancel()
                }
            })

        // the .loading initial state:
        navigationController?.isToolbarHidden = true
        navigationController?.isNavigationBarHidden = true
        // eof .loading initial state

        definesPresentationContext = true
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
        searchController.automaticallyShowsCancelButton = false
        searchController.delegate = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.showsSearchResultsController = true
        searchController.searchBar.searchTextField.placeholder = LocalString.common_search

        searchTextObserver = searchViewModel.$searchText.sink { [weak self] searchText in
            guard self?.searchController.searchBar.text != searchText else { return }
            self?.searchController.searchBar.text = searchText
        }
        openURLObserver = NotificationCenter.default.addObserver(
            forName: .openURL, object: nil, queue: nil
        ) { [weak self] _ in
            self?.searchController.isActive = false
            self?.navigationItem.setRightBarButton(nil, animated: true)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func willPresentSearchController(_ searchController: UISearchController) {
        navigationController?.setToolbarHidden(true, animated: true)
        trailingNavItemGroups = navigationItem.trailingItemGroups
        navigationItem.setRightBarButton(
            UIBarButtonItem(
                title: LocalString.common_button_cancel,
                style: .done,
                target: self,
                action: #selector(onSearchCancelled)
            ),
            animated: true
        )
    }
    @objc func onSearchCancelled() {
        searchController.isActive = false
        navigationItem.setRightBarButtonItems(nil, animated: false)
        navigationItem.trailingItemGroups = trailingNavItemGroups
    }

    func willDismissSearchController(_ searchController: UISearchController) {
        navigationController?.setToolbarHidden(false, animated: true)
        searchViewModel.searchText = ""
        navigationItem.trailingItemGroups = trailingNavItemGroups
    }

    func updateSearchResults(for searchController: UISearchController) {
        searchViewModel.searchText = searchController.searchBar.text ?? ""
    }
}

private struct CompactViewWrapper: View {
    @EnvironmentObject private var navigation: NavigationViewModel
    
    var body: some View {
        if case .loading = navigation.currentItem {
            LoadingDataView()
        } else if case let .tab(tabID) = navigation.currentItem {
            CompactView(tabID: tabID)
        }
    }
}

private struct CompactView: View {
    @EnvironmentObject private var navigation: NavigationViewModel
    @EnvironmentObject private var library: LibraryViewModel
    @State private var presentedSheet: PresentedSheet?
    @ObservedObject private var browser: BrowserViewModel
    @FocusedValue(\.hasZIMFiles) var hasZimFiles
    private let navigateToHotspotSettings = NotificationCenter.default.publisher(for: .navigateToHotspotSettings)
    private let hotspotShareURL = NotificationCenter.default.publisher(for: .hotspotShareURL)
    
    private enum PresentedSheet: Identifiable {
        case library(downloads: Bool)
        case hotspotShare(url: URL)
        case settings(scrollToHotspot: Bool)
        var id: String {
            switch self {
            case .library(true): return "library-downloads"
            case .library(false): return "library"
            case .hotspotShare: return "hotspot-share"
            case .settings: return "settings"
            }
        }
    }
    
    init(tabID: NSManagedObjectID) {
        self.browser = BrowserViewModel.getCached(tabID: tabID)
    }
    
    private func dismiss() {
        presentedSheet = nil
    }
    
    var body: some View {
        let model = if FeatureFlags.hasLibrary {
            CatalogLaunchViewModel(library: library, browser: browser)
        } else {
            NoCatalogLaunchViewModel(browser: browser)
        }
        Content(
            browser: browser,
            tabID: browser.tabID,
            showLibrary: {
                if presentedSheet == nil {
                    presentedSheet = .library(downloads: false)
                } else {
                    // there's a sheet already presented by the user
                    // do nothing
                }
            },
            showSettings: {
                presentedSheet = .settings(scrollToHotspot: false)
            },
            model: model)
        .id(browser.tabID)
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Spacer()
                NavigationButtons(
                    goBack: { [weak browser] in
                        browser?.webView.goBack()
                    },
                    goForward: { [weak browser] in
                        browser?.webView.goForward()
                    })
                SpacerBackCompatible()
                TabsManagerButton()
                SpacerBackCompatible()
                if FeatureFlags.hasLibrary {
                    Button {
                        presentedSheet = .library(downloads: false)
                    } label: {
                        Label(LocalString.common_tab_menu_library, systemImage: "folder")
                    }.accessibilityIdentifier("Library")
                    SpacerBackCompatible()
                }
                if !Brand.hideTOCButton {
                    OutlineButton(browser: browser)
                    SpacerBackCompatible()
                }
                MoreTabButton(browser: browser)
                Spacer()
            }
        }
        .sheet(item: $presentedSheet) { presentedSheet in
            switch presentedSheet {
            case .library(downloads: false):
                Library(dismiss: dismiss)
            case .library(downloads: true):
                Library(dismiss: dismiss, tabItem: .downloads)
            case .hotspotShare(let url):
                // comes from HotspotZimFilesSelection
                ActivityViewController(activityItems: [url].compactMap { $0 })
            case .settings(let scrollToHotspot):
                NavigationStack {
                    Settings(scrollToHotspot: scrollToHotspot).toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                self.presentedSheet = nil
                            } label: {
                                Text(LocalString.common_button_done).fontWeight(.semibold)
                            }
                        }
                    }
                }
            }
        }
        .onReceive(navigation.showDownloads) { _ in
            switch presentedSheet {
            case .library:
                // switching to the downloads tab
                // is done within Library
                break
            case .hotspotShare:
                // doesn't apply
                break
            case .settings, nil:
                presentedSheet = .library(downloads: true)
            }
        }
        .onReceive(hotspotShareURL) { notification in
            guard let url = notification.userInfo?["url"] as? URL else {
                return
            }
            presentedSheet = .hotspotShare(url: url)
        }
        .onReceive(navigateToHotspotSettings) { _ in
            presentedSheet = .settings(scrollToHotspot: true)
        }
    }
}

private struct Content<LaunchModel>: View where LaunchModel: LaunchProtocol {
    @ObservedObject var browser: BrowserViewModel
    let tabID: NSManagedObjectID?
    let showLibrary: () -> Void
    let showSettings: () -> Void
    @ObservedObject var model: LaunchModel
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var library: LibraryViewModel
    @EnvironmentObject private var navigation: NavigationViewModel
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.openedPredicate
    ) private var zimFiles: FetchedResults<ZimFile>
    
    /// this is still hacky a bit, as the change from here re-validates the view
    /// which triggers the model to be revalidated
    @Default(.hasSeenCategories) private var hasSeenCategories

    var body: some View {
        Group {
            // swiftlint:disable:next redundant_discardable_let
            let _ = model.updateWith(hasZimFiles: !zimFiles.isEmpty,
                                     hasSeenCategories: hasSeenCategories)
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
                }
            case .catalog(let catalogSequence):
                switch catalogSequence {
                case .fetching:
                    FetchingCatalogView()
                case .list:
                    LocalLibraryList(browser: browser)
                case .welcome(let welcomeViewState):
                    WelcomeCatalog(viewState: welcomeViewState)
                }
            }
        }
        .focusedSceneValue(\.isBrowserURLSet, browser.url != nil)
        .focusedSceneValue(\.canGoBack, browser.canGoBack)
        .focusedSceneValue(\.canGoForward, browser.canGoForward)
        .focusedSceneValue(\.hasZIMFiles, zimFiles.isEmpty == false)
        .modifier(ExternalLinkHandler(externalURL: $browser.externalURL))
        .onAppear { [weak browser] in
            browser?.updateLastOpened()
        }
        .onDisappear { [weak browser] in
            if tabID != nil {
                browser?.pauseVideoWhenNotInPIP()
                browser?.persistState()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if !Brand.hideFindInPage {
                    ContentSearchButton(browser: browser)
                }
                Button {
                    showSettings()
                } label: {
                    Label(LocalString.common_tab_menu_settings, systemImage: "gear")
                }
            }
        }
        .onChange(of: scenePhase) { newValue in
            if case .active = newValue {
                browser.refreshVideoState()
            }
        }
        .onChange(of: library.state) { state in
            guard state == .complete else { return }
            showTheLibrary()
        }
    }

    private func showTheLibrary() {
        guard model.state.shouldShowCatalog else { return }
        #if os(macOS)
        navigation.currentItem = .categories
        #else
        if horizontalSizeClass == .regular {
            navigation.currentItem = .categories
        } else {
            showLibrary()
        }
        #endif
    }
}
#endif
