//
//  RootView_iOS.swift
//  Kiwix for iOS
//
//  Created by Chris Li on 8/2/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

import Introspect

/// Root view for iOS & iPadOS
struct RootView_iOS: UIViewControllerRepresentable {
    @Binding var url: URL?
    @State private var isSearchActive = false
    @StateObject private var searchViewModel = SearchViewModel()
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let view = Content(isSearchActive: $isSearchActive, url: $url).environmentObject(searchViewModel)
        let controller = UIHostingController(rootView: view)
        let navigationController = UINavigationController(rootViewController: controller)
        
        // configure search bar
        let searchBar = UISearchBar()
        searchBar.autocorrectionType = .no
        searchBar.autocapitalizationType = .none
        searchBar.delegate = context.coordinator
        searchBar.placeholder = "Search"
        searchBar.searchBarStyle = .minimal
        
        // configure navigation item
        controller.navigationItem.titleView = searchBar
        if #available(iOS 15.0, *) {
            controller.navigationItem.scrollEdgeAppearance = {
                let apperance = UINavigationBarAppearance()
                apperance.configureWithDefaultBackground()
                return apperance
            }()
            navigationController.toolbar.scrollEdgeAppearance = {
                let apperance = UIToolbarAppearance()
                apperance.configureWithDefaultBackground()
                return apperance
            }()
        }
        
        // observe bookmark toggle notification
        context.coordinator.bookmarkToggleObserver = NotificationCenter.default.addObserver(
            forName: ReaderViewModel.bookmarkNotificationName, object: nil, queue: nil
        ) { notification in
            let isBookmarked = notification.object != nil
            let hudController = HUDController()
            hudController.modalPresentationStyle = .custom
            hudController.transitioningDelegate = hudController
            hudController.direction = isBookmarked ? .down : .up
            hudController.imageView.image = isBookmarked ? #imageLiteral(resourceName: "StarAdd") : #imageLiteral(resourceName: "StarRemove")
            hudController.label.text = isBookmarked ?
                NSLocalizedString("Added", comment: "Bookmark HUD") :
                NSLocalizedString("Removed", comment: "Bookmark HUD")
            controller.present(hudController, animated: true) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    hudController.dismiss(animated: true, completion: nil)
                }
            }
        }
        
        return navigationController
    }
    
    func updateUIViewController(_ navigationController: UINavigationController, context: Context) {
        guard let searchBar = navigationController.topViewController?.navigationItem.titleView as? UISearchBar else { return }
        
        if isSearchActive {
            searchBar.text = searchViewModel.searchText
        } else {
            // Triggers "AttributeGraph: cycle detected through attribute" if not dispatched (iOS 16.0 SDK)
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
        }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, UISearchBarDelegate {
        let rootView: RootView_iOS
        var bookmarkToggleObserver: NSObjectProtocol?
        
        init(_ rootView: RootView_iOS) {
            self.rootView = rootView
            super.init()
        }
        
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            rootView.searchViewModel.searchText = searchText
        }
        
        func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
            withAnimation {
                rootView.isSearchActive = true
            }
        }
        
        func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
            searchBar.text = ""
            rootView.searchViewModel.searchText = ""
        }
    }
}

private struct Content: View {
    @Binding var isSearchActive: Bool
    @Binding var url: URL?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @EnvironmentObject var viewModel: ReadingViewModel
    
    var body: some View {
        ZStack {
            if url == nil {
                Welcome(url: $url)
            } else {
                WebView(url: $url).ignoresSafeArea(.container, edges: .all)
            }
            if isSearchActive {
                SearchView(url: $url)
            }
        }
        .onChange(of: url) { _ in isSearchActive = false }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                if horizontalSizeClass == .regular, !isSearchActive {
                    NavigateBackButton()
                    NavigateForwardButton()
                    OutlineMenu()
                    BookmarkMultiButton(url: url)
                }
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if horizontalSizeClass == .regular, !isSearchActive {
                    if #available(iOS 15.0, *) {
                        RandomArticleMenu(url: $url)
                    } else {
                        RandomArticleButton(url: $url)
                    }
                    if #available(iOS 15.0, *) {
                        MainArticleMenu(url: $url)
                    } else {
                        MainArticleButton(url: $url)
                    }
                    LibraryButton()
                    SettingsButton()
                } else if isSearchActive {
                    Button("Cancel") {
                        isSearchActive = false
                    }
                }
            }
            ToolbarItemGroup(placement: .bottomBar) {
                if horizontalSizeClass == .compact, !isSearchActive {
                    Group {
                        NavigateBackButton()
                        Spacer()
                        NavigateForwardButton()
                    }
                    Spacer()
                    OutlineButton()
                    Spacer()
                    BookmarkMultiButton(url: url)
                    Spacer()
                    if #available(iOS 15.0, *) {
                        RandomArticleMenu(url: $url)
                    } else {
                        RandomArticleButton(url: $url)
                    }
                    Spacer()
                    MoreActionMenu(url: $url)
                }
            }
        }
        .introspectNavigationController { controller in
            controller.setToolbarHidden(horizontalSizeClass != .compact || isSearchActive, animated: false)
        }
    }
}
