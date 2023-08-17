//
//  CompactLegacyView.swift
//  Kiwix
//
//  Created by Chris Li on 8/3/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import SwiftUI

#if os(iOS)
struct ContainerView<Content: View>: UIViewControllerRepresentable {
    @StateObject private var search = SearchViewModel()
    
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let controller = UIHostingController(rootView: self.content.environmentObject(search))
        controller.navigationItem.scrollEdgeAppearance = {
            let apperance = UINavigationBarAppearance()
            apperance.configureWithDefaultBackground()
            return apperance
        }()
        controller.navigationItem.titleView = context.coordinator.searchBar
        let navigation = UINavigationController(rootViewController: controller)
        navigation.isToolbarHidden = false
        navigation.toolbar.scrollEdgeAppearance = {
            let apperance = UIToolbarAppearance()
            apperance.configureWithDefaultBackground()
            return apperance
        }()
        return navigation
    }
    
    func updateUIViewController(_ navigationController: UINavigationController, context: Context) {
        if search.isSearching {
            DispatchQueue.main.async {
                context.coordinator.searchBar.text = search.searchText
            }
        } else {
            DispatchQueue.main.async {
                context.coordinator.searchBar.resignFirstResponder()
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(view: self)
    }
    
    class Coordinator: NSObject, UISearchBarDelegate {
        let view: ContainerView
        let searchBar = UISearchBar()
        
        init(view: ContainerView) {
            self.view = view
            searchBar.autocorrectionType = .no
            searchBar.autocapitalizationType = .none
            searchBar.placeholder = "Search"
            searchBar.searchBarStyle = .minimal
            super.init()
            searchBar.delegate = self
        }
        
        func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
            view.search.isSearching = true
        }
        
        func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
            searchBar.text = ""
            view.search.isSearching = false
            view.search.searchText = ""
        }
        
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            guard view.search.searchText != searchText else { return }
            view.search.searchText = searchText
        }
    }
}

@available(iOS 16.0, *)
struct CompactView: View {
    @EnvironmentObject private var navigation: NavigationViewModel
    @EnvironmentObject private var search: SearchViewModel
    @StateObject private var browser = BrowserViewModel()
    
    var body: some View {
        Group {
            if search.isSearching {
                SearchResults()
            } else if case let .tab(tabID) = navigation.currentItem, browser.url != nil {
                WebView(tabID: tabID).ignoresSafeArea().id(tabID)
            } else {
                Welcome()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if search.isSearching {
                    Button("Cancel") {
                        search.isSearching = false
                    }
                }
            }
            ToolbarItemGroup(placement: .bottomBar) {
                if !search.isSearching {
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
        }
        .environmentObject(browser)
        .onAppear {
            guard case let .tab(tabID) = navigation.currentItem else { return }
            browser.configure(tabID: tabID)
        }
        .onChange(of: navigation.currentItem) { navigationItem in
            guard case let .tab(tabID) = navigation.currentItem else { return }
            browser.configure(tabID: tabID)
        }
    }
}

struct LegacyView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var navigation: NavigationViewModel
    @EnvironmentObject private var search: SearchViewModel
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.openedPredicate
    ) private var zimFiles: FetchedResults<ZimFile>
    @State private var presentedSheet: PresentedSheet?
    @StateObject private var browser = BrowserViewModel()
    
    enum PresentedSheet: String, Identifiable {
        var id: String { rawValue }
        case library, settings
    }
    
    var body: some View {
        Group {
            if search.isSearching {
                SearchResults()
            } else if browser.url == nil {
                Welcome()
            } else {
                WebView(tabID: nil).ignoresSafeArea()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                if horizontalSizeClass == .regular, !search.isSearching {
                    NavigationButtons()
                    OutlineButton()
                    BookmarkButton()
                }
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if horizontalSizeClass == .regular, !search.isSearching {
                    RandomArticleButton()
                    MainArticleButton()
                    Button {
                        presentedSheet = .library
                    } label: {
                        Label("Library", systemImage: "folder")
                    }
                    Button {
                        presentedSheet = .settings
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                } else if search.isSearching {
                    Button("Cancel") {
                        search.isSearching = false
                    }
                }
            }
            ToolbarItemGroup(placement: .bottomBar) {
                if horizontalSizeClass == .compact, !search.isSearching {
                    NavigationButtons()
                    Spacer()
                    OutlineButton()
                    Spacer()
                    BookmarkButton()
                    Spacer()
                    RandomArticleButton()
                    Spacer()
                    Menu {
                        Section {
                            ForEach(zimFiles) { zimFile in
                                Button {
                                    guard let url = ZimFileService.shared.getMainPageURL(zimFileID: zimFile.id) else { return }
                                    browser.load(url: url)
                                } label: {
                                    Label(zimFile.name, systemImage: "house")
                                }
                            }
                        }
                        Button {
                            presentedSheet = .library
                        } label: {
                            Label("Library", systemImage: "folder")
                        }
                        Button {
                            presentedSheet = .settings
                        } label: {
                            Label("Settings", systemImage: "gear")
                        }
                    } label: {
                        Label("More Actions", systemImage: "ellipsis.circle")
                    }
                }
            }
        }
        .environmentObject(browser)
        .onAppear {
            browser.configure(tabID: nil)
        }
        .onChange(of: browser.url) { _ in
            search.isSearching = false
            presentedSheet = nil
        }
        .sheet(item: $presentedSheet) { presentedSheet in
            switch presentedSheet {
            case .library:
                Library()
            case .settings:
                SheetContent { Settings() }
            }
        }
    }
}
#endif
