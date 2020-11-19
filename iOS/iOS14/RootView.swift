//
//  RootView.swift
//  Kiwix
//
//  Created by Chris Li on 10/18/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import SwiftUI
import UIKit

@available(iOS 14.0, *)
struct RootView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject var sceneViewModel: SceneViewModel
    @EnvironmentObject var searchViewModel: SearchViewModel
    
    var body: some View {
        switch (searchViewModel.isActive, horizontalSizeClass) {
        case (true, _):
            SearchView().toolbar { ToolbarItem(placement: .navigationBarTrailing) { SearchCancelButton() } }
        case (false, .regular):
            SplitView().toolbar { NavigationBarContent() }
        case (false, .compact):
            ContentView().toolbar { BottomBarContent() }
        default:
            EmptyView()
        }
    }
}

@available(iOS 14.0, *)
struct NavigationBarContent: ToolbarContent {
    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) { GoBackButton() }
        ToolbarItem(placement: .navigationBarLeading) { GoForwardButton() }
        ToolbarItem(placement: .navigationBarLeading) { BookmarkArtilesButton() }
        ToolbarItem(placement: .navigationBarLeading) { RecentArticlesButton() }
        ToolbarItem(placement: .navigationBarTrailing) { RandomArticlesButton() }
        ToolbarItem(placement: .navigationBarTrailing) { TableOfContentsButton() }
        ToolbarItem(placement: .navigationBarTrailing) { MapButton() }
        ToolbarItem(placement: .navigationBarTrailing) { ZStack { Spacer(); HomeButton() } }
    }
}

@available(iOS 14.0, *)
struct BottomBarContent: ToolbarContent {
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            GoBackButton()
            Spacer()
            GoForwardButton()
        }
        ToolbarItem(placement: .bottomBar) { Spacer() }
        ToolbarItemGroup(placement: .bottomBar) {
            BookmarkArtilesButton()
            Spacer()
            TableOfContentsButton()
            Spacer()
            RandomArticlesButton()
        }
        ToolbarItem(placement: .bottomBar) { Spacer() }
        ToolbarItem(placement: .bottomBar) {
            ZStack {
                Spacer()
                HomeButton()
            }
        }
    }
}

@available(iOS 14.0, *)
class RootController_iOS14: UIHostingController<AnyView> {
    private let sceneViewModel = SceneViewModel()
    private let searchViewModel = SearchViewModel()
    private let zimFilesViewModel = ZimFilesViewModel()

    init() {
        let view = RootView()
            .environmentObject(sceneViewModel)
            .environmentObject(searchViewModel)
            .environmentObject(zimFilesViewModel)
        super.init(rootView: AnyView(view))
        navigationItem.titleView = searchViewModel.searchBar
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@available(iOS 14.0, *)
private struct SplitView: UIViewControllerRepresentable {
    @Environment(\.sidebarDisplayMode) var sidebarDisplayMode
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UISplitViewController(style: .doubleColumn)
        controller.setViewController(UIHostingController(rootView: SidebarView().navigationBarHidden(true)), for: .primary)
        controller.setViewController(UIHostingController(rootView: ContentView().navigationBarHidden(true)), for: .secondary)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }
}

@available(iOS 14.0, *)
struct ContentView: View {
    @EnvironmentObject var sceneViewModel: SceneViewModel
    
    var body: some View {
        switch sceneViewModel.contentDisplayMode {
        case .homeView:
            HomeView()
        case .webView:
            WebView()
        case .transitionView:
            Color(.systemBackground)
        }
    }
}
