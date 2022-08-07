//
//  RootView_iOS.swift
//  Kiwix for iOS
//
//  Created by Chris Li on 8/2/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

/// Root view for iOS & iPadOS
struct RootView_iOS: UIViewControllerRepresentable {
    @State private var isSearchActive = false
    @State private var searchText = ""
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let controller = UIHostingController(rootView: Content(isSearchActive: $isSearchActive))
        let navigationController = UINavigationController(rootViewController: controller)
        controller.definesPresentationContext = true
        
        // configure search
        context.coordinator.searchController.delegate = context.coordinator
        context.coordinator.searchController.searchBar.autocorrectionType = .no
        context.coordinator.searchController.searchBar.autocapitalizationType = .none
        context.coordinator.searchController.searchBar.searchBarStyle = .minimal
        context.coordinator.searchController.hidesNavigationBarDuringPresentation = false
        context.coordinator.searchController.searchResultsUpdater = context.coordinator
        context.coordinator.searchController.automaticallyShowsCancelButton = false
        context.coordinator.searchController.showsSearchResultsController = true
        context.coordinator.searchController.obscuresBackgroundDuringPresentation = true
        
        // configure navigation item
        controller.navigationItem.titleView = context.coordinator.searchController.searchBar
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
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        if !isSearchActive {
            DispatchQueue.main.async {
                context.coordinator.searchController.isActive = false
            }
        }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, UISearchControllerDelegate, UISearchResultsUpdating {
        let rootView: RootView_iOS
        let searchController: UISearchController
        var bookmarkToggleObserver: NSObjectProtocol?
        
        init(_ rootView: RootView_iOS) {
            self.rootView = rootView
            let searchResultsController = UIHostingController(rootView: Search(searchText: rootView.$searchText))
            self.searchController = UISearchController(searchResultsController: searchResultsController)
            super.init()
        }
        
        func willPresentSearchController(_ searchController: UISearchController) {
            withAnimation {
                rootView.isSearchActive = true
            }
        }
        
        func updateSearchResults(for searchController: UISearchController) {
            guard rootView.isSearchActive else { return }
            rootView.searchText = searchController.searchBar.text ?? ""
        }
    }
}

private struct Content: View {
    @Binding var isSearchActive: Bool
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var url: URL?
    @StateObject private var viewModel = ReadingViewModel()
    
    var body: some View {
        Group {
            if url == nil {
                Welcome(url: $url)
            } else {
                WebView(url: $url).ignoresSafeArea(.container, edges: .all)
            }
        }
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
        .sheet(item: $viewModel.activeSheet) { activeSheet in
            switch activeSheet {
            case .outline:
                SheetView { OutlineTree().listStyle(.plain).navigationBarTitleDisplayMode(.inline) }
            case .bookmarks:
                SheetView { BookmarksView(url: $url) }
            }
        }
        .onChange(of: url) { _ in
            viewModel.activeSheet = nil
        }
        .environment(\.managedObjectContext, Database.shared.container.viewContext)
        .environmentObject(viewModel)
    }
}
