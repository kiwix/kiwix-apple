//
//  CompactViewController.swift
//  Kiwix

#if os(iOS)
import Combine
import SwiftUI
import UIKit

final class CompactViewController: UIHostingController<AnyView>, UISearchControllerDelegate, UISearchResultsUpdating {
    private let searchViewModel: SearchViewModel
    private let searchController: UISearchController
    private var searchTextObserver: AnyCancellable?
    private var openURLObserver: NSObjectProtocol?

    private var trailingNavItemGroups: [UIBarButtonItemGroup] = []
    private var rightNavItem: UIBarButtonItem?

    init() {
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
        if #available(iOS 16.0, *) {
            trailingNavItemGroups = navigationItem.trailingItemGroups
        } else {
            rightNavItem = navigationItem.rightBarButtonItem
        }
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
        if #available(iOS 16.0, *) {
            navigationItem.setRightBarButtonItems(nil, animated: false)
            navigationItem.trailingItemGroups = trailingNavItemGroups
        } else {
            navigationItem.setRightBarButtonItems([rightNavItem].compactMap { $0 }, animated: true)
        }
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
    @State private var presentedSheet: PresentedSheet?

    private enum PresentedSheet: String, Identifiable {
        var id: String { rawValue }
        case library, settings
    }

    var body: some View {
        if case let .tab(tabID) = navigation.currentItem {
            Content()
                .id(tabID)
                .toolbar {
                    ToolbarItemGroup(placement: .bottomBar) {
                        HStack {
                            NavigationButtons()
                            Spacer()
                            OutlineButton()
                            Spacer()
                            BookmarkButton()
                            Spacer()
                            TabsManagerButton()
                            if FeatureFlags.hasLibrary {
                                Spacer()
                                Button {
                                    presentedSheet = .library
                                } label: {
                                    Label("common.tab.menu.library".localized, systemImage: "folder")
                                }
                            }
                            Spacer()
                            Button {
                                presentedSheet = .settings
                            } label: {
                                Label("common.tab.menu.settings".localized, systemImage: "gear")
                            }
                        }
                    }
                }
                .environmentObject(BrowserViewModel.getCached(tabID: tabID))
                .sheet(item: $presentedSheet) { presentedSheet in
                    switch presentedSheet {
                    case .library:
                        Library()
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

private struct Content: View {
    @EnvironmentObject private var browser: BrowserViewModel
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.openedPredicate
    ) private var zimFiles: FetchedResults<ZimFile>

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
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("article_shortcut.random.button.title.ios".localized,
                       systemImage: "die.face.5",
                       action: { browser.loadRandomArticle() })
                .disabled(zimFiles.isEmpty)
            }
        }
    }
}
#endif
