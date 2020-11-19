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
    @Environment(\.colorScheme) private var colorScheme
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
private struct SplitView: UIViewControllerRepresentable {
    @EnvironmentObject var sceneViewModel: SceneViewModel
    
    func makeUIViewController(context: Context) -> UISplitViewController {
        let sidebarController = UIHostingController(rootView: SidebarView().navigationBarHidden(true))
        let contentController = UIHostingController(rootView: ContentView().navigationBarHidden(true))
        
        let controller = UISplitViewController(style: .doubleColumn)
        controller.delegate = context.coordinator
        controller.presentsWithGesture = false
        controller.setViewController(sidebarController, for: .primary)
        controller.setViewController(contentController, for: .secondary)
        return controller
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(sceneViewModel)
    }
    
    func updateUIViewController(_ uiViewController: UISplitViewController, context: Context) {
        if sceneViewModel.sidebarDisplayMode == .none {
            uiViewController.hide(.primary)
        } else {
            uiViewController.show(.primary)
        }
    }
    
    class Coordinator: NSObject, UISplitViewControllerDelegate {
        let sceneViewModel: SceneViewModel
        
        init(_ sceneViewModel: SceneViewModel) {
            self.sceneViewModel = sceneViewModel
        }
        
        func splitViewController(_ svc: UISplitViewController, willHide column: UISplitViewController.Column) {
            guard column == .primary else { return }
            sceneViewModel.sidebarDisplayMode = .none
        }
    }
}

@available(iOS 14.0, *)
struct NavigationBarContent: ToolbarContent {
    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) { GoBackButton() }
        ToolbarItem(placement: .navigationBarLeading) { GoForwardButton() }
        ToolbarItem(placement: .navigationBarLeading) { BookmarksButton() }
        ToolbarItem(placement: .navigationBarLeading) { OutlineButton() }
        ToolbarItem(placement: .navigationBarTrailing) { RandomArticlesButton() }
        ToolbarItem(placement: .navigationBarTrailing) { RecentArticlesButton() }
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
            BookmarksButton()
            Spacer()
            OutlineButton()
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
struct SidebarView: View {
    @EnvironmentObject var sceneViewModel: SceneViewModel
    
    var body: some View {
        switch sceneViewModel.sidebarDisplayMode {
        case .bookmark:
            Text("bookmark!")
        case .outline:
            Text("outline!")
        default:
            EmptyView()
        }
    }
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
