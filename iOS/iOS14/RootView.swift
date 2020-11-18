//
//  RootView.swift
//  Kiwix
//
//  Created by Chris Li on 10/18/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import SwiftUI
import UIKit
import WebKit

@available(iOS 14.0, *)
enum SidebarDisplayMode {
    case hidden, bookmark, recent
}

@available(iOS 14.0, *)
struct RootView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject var sceneViewModel: SceneViewModel
    @EnvironmentObject var searchViewModel: SearchViewModel
    @State private var sidebarDisplayMode = SidebarDisplayMode.hidden
    @State private var showSidebar = false
    
    private let sidebarAnimation = Animation.easeOut(duration: 0.2)
    private let sidebarWidth: CGFloat = 320.0
    
    var content: some View {
        ZStack {
            if searchViewModel.isActive {
                SearchView()
            } else {
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
        .sheet(item: $sceneViewModel.currentExternalURL, content: { url in
            SafariView(url: url).ignoresSafeArea(edges: .bottom)
        })
    }
    
    var body: some View {
        switch (horizontalSizeClass, searchViewModel.isActive) {
        case (_, true):
            content.toolbar { ToolbarItem(placement: .navigationBarTrailing) { SearchCancelButton() } }
        case (.regular, false):
            content.toolbar { NavigationBarContent() }
        case (.compact, false):
            content.toolbar { BottomBarContent() }
        default:
            EmptyView()
        }
    }
    
    var navigationBarLeadingView: some View {
        HStack {
            GoBackButton()
            GoForwardButton()
            BookmarkArtilesButton()
            RecentArticlesButton()
        }
        .padding(.trailing, 16)
    }
    
    var navigationBarTrailingView: some View {
        HStack(spacing: 12) {
            RandomArticlesButton()
            TableOfContentsButton()
            MapButton()
            HomeButton()
        }.padding(.leading, 16)
    }
    
    
    // MARK: - Button Actions
    
    private func showBookmark() {
        if horizontalSizeClass == .regular {
            withAnimation(sidebarAnimation) { showSidebar = true }
        }
    }
    
    private func showRecent() {
        if horizontalSizeClass == .regular {
            withAnimation(sidebarAnimation) { showSidebar = true }
        }
    }
    
    private func hideSideBar() {
        withAnimation(sidebarAnimation) { showSidebar = false }
    }
}

@available(iOS 14.0, *)
struct SplitView: UIViewControllerRepresentable {
    let sidebarView: SidebarView
    let contentView: ContentView
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UISplitViewController()
        controller.setViewController(UIHostingController(rootView: sidebarView), for: .primary)
        controller.setViewController(UIHostingController(rootView: contentView), for: .secondary)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }
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
struct WebView: UIViewRepresentable {
    @EnvironmentObject var sceneViewModel: SceneViewModel
    
    func makeUIView(context: Context) -> WKWebView {
        return sceneViewModel.webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        
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
struct SidebarView: View {
    var body: some View {
        Text("Sidebar!")
    }
}

@available(iOS 14.0, *)
struct ContentView: View {
    var body: some View {
        Text("Content!")
    }
}
