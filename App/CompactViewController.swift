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
        searchViewModel = SearchViewModel()
        let searchResult = SearchResults().environmentObject(searchViewModel)
        searchController = UISearchController(searchResultsController: UIHostingController(rootView: searchResult))
        super.init(rootView: AnyView(CompactView()))
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
        searchController.searchBar.searchTextField.placeholder = "common.search".localized

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

private struct CompactView: View {
    @EnvironmentObject private var navigation: NavigationViewModel
    @EnvironmentObject private var library: LibraryViewModel
    @State private var presentedSheet: PresentedSheet?

    private enum PresentedSheet: String, Identifiable {
        case library
        case settings
        var id: String {
            rawValue
        }
    }

    private func dismiss() {
        presentedSheet = nil
    }

    var body: some View {
        if case .loading = navigation.currentItem {
            LoadingView()
        } else if case let .tab(tabID) = navigation.currentItem {
            let browser = BrowserViewModel.getCached(tabID: tabID)
            let model = if FeatureFlags.hasLibrary {
                CatalogLaunchViewModel(library: library, browser: browser)
            } else {
                NoCatalogLaunchViewModel(browser: browser)
            }
            Content(tabID: tabID, showLibrary: {
                if presentedSheet == nil {
                    presentedSheet = .library
                } else {
                    // there's a sheet already presented by the user
                    // do nothing
                }
            }, model: model)
                .id(tabID)
                .toolbar {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Spacer()
                        NavigationButtons()
                        Spacer()
                        OutlineButton()
                        Spacer()
                        BookmarkButton()
                        Spacer()
                        ExportButton()
                        Spacer()
                        TabsManagerButton()
                        Spacer()
                        if FeatureFlags.hasLibrary {
                            Button {
                                presentedSheet = .library
                            } label: {
                                Label("common.tab.menu.library".localized, systemImage: "folder")
                            }
                            Spacer()
                        }
                        Button {
                            presentedSheet = .settings
                        } label: {
                            Label("common.tab.menu.settings".localized, systemImage: "gear")
                        }
                        Spacer()
                    }
                }
                .environmentObject(browser)
                .sheet(item: $presentedSheet) { presentedSheet in
                    switch presentedSheet {
                    case .library:
                        Library(dismiss: dismiss)
                    case .settings:
                        NavigationView {
                            Settings().toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    Button {
                                        self.presentedSheet = nil
                                    } label: {
                                        Text("common.button.done".localized).fontWeight(.semibold)
                                    }
                                }
                            }
                        }
                    }
                }
        }
    }
}

private struct Content<LaunchModel>: View where LaunchModel: LaunchProtocol {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var browser: BrowserViewModel
    @EnvironmentObject private var library: LibraryViewModel
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.openedPredicate
    ) private var zimFiles: FetchedResults<ZimFile>
    @State var isInitialLoad: Bool = true
    
    /// this is still hacky a bit, as the change from here re-validates the view
    /// which triggers the model to be revalidated
    @Default(.hasSeenCategories) private var hasSeenCategories
    let tabID: NSManagedObjectID?
    let showLibrary: () -> Void
    @ObservedObject var model: LaunchModel

    var body: some View {
        Group {
            let _ = model.updateWith(hasZimFiles: !zimFiles.isEmpty,
                                     hasSeenCategories: hasSeenCategories)
            let _ = debugPrint("model.state: \(model.state)")
            if browser.url == nil || (!FeatureFlags.hasLibrary && isInitialLoad) {
                Welcome(showLibrary: showLibrary)
            } else {
                WebView().ignoresSafeArea()
                    .overlay {
                        if browser.isLoading == true {
                            LoadingProgressView()
                        }
                    }
            }
        }
        .focusedSceneValue(\.browserViewModel, browser)
        .focusedSceneValue(\.canGoBack, browser.canGoBack)
        .focusedSceneValue(\.canGoForward, browser.canGoForward)
        .modifier(ExternalLinkHandler(externalURL: $browser.externalURL))
        .onAppear {
            browser.updateLastOpened()
        }
        .task {
            debugPrint("library: \(library)")
            debugPrint("")
        }
        .onDisappear {
            // since the browser is comming from @Environment,
            // by the time we get to .onDisappear,
            // it will reference not this, but the new Tab we switched to.
            // Therefore we need to find this browser again by tabID
            if let tabID {
                let thisBrowser = BrowserViewModel.getCached(tabID: tabID)
                thisBrowser.pauseVideoWhenNotInPIP()
                thisBrowser.persistState()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("article_shortcut.random.button.title.ios".localized,
                       systemImage: "die.face.5",
                       action: { browser.loadRandomArticle() })
                .disabled(zimFiles.isEmpty)
                ContentSearchButton()
            }
        }
        .onChange(of: scenePhase) { newValue in
            if case .active = newValue {
                browser.refreshVideoState()
            }
        }
        .onChange(of: browser.isLoading) { isLoading in
            if isLoading == false { // wait for the first full webpage load
                isInitialLoad = false
            }
        }
    }
}
#endif
