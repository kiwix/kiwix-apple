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
struct RootView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject var sceneViewModel: SceneViewModel
    @EnvironmentObject var searchViewModel: SearchViewModel
    
    @State var isSheetPresented = false
    
    var body: some View {
        switch (searchViewModel.isActive, horizontalSizeClass) {
        case (true, _):
            SearchView().toolbar { ToolbarItem(placement: .navigationBarTrailing) { SearchCancelButton() } }
        case (false, .regular):
            SplitView()
                .ignoresSafeArea()
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        GoBackButton()
                        GoForwardButton()
                        BookmarksButton()
                        OutlineButton(isSheetPresented: $isSheetPresented)
                    }
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        RandomArticlesButton()
                        RecentArticlesButton()
                        MapButton()
                        HouseButton()
                    }
                }
        case (false, .compact):
            ContentView()
                .sheet(isPresented: $isSheetPresented) { SheetView(isSheetPresented: $isSheetPresented) }
                .toolbar {
                    ToolbarItemGroup(placement: .bottomBar) {
                        GoBackButton()
                        Spacer()
                        GoForwardButton()
                        Spacer()
                        BookmarksButton()
                        Spacer()
                        OutlineButton(isSheetPresented: $isSheetPresented)
                        Spacer()
                        RandomArticlesButton()
                        Spacer()
                        
                    }
                    ToolbarItem(placement: .bottomBar) { HouseButton() }
                }
        default:
            EmptyView()
        }
    }
}

@available(iOS 14.0, *)
private struct SplitView: UIViewControllerRepresentable {
    @EnvironmentObject var sceneViewModel: SceneViewModel
    
    func makeUIViewController(context: Context) -> UISplitViewController {
        let sidebarView = SidebarView().navigationBarHidden(true).environmentObject(sceneViewModel)
        let contentView = ContentView().navigationBarHidden(true).environmentObject(sceneViewModel)
        let sidebarController = UIHostingController(rootView: sidebarView)
        let contentController = UIHostingController(rootView: contentView)
        
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
        if sceneViewModel.isSidebarVisible {
            uiViewController.show(.primary)
        } else {
            uiViewController.hide(.primary)
        }
    }
    
    class Coordinator: NSObject, UISplitViewControllerDelegate {
        let sceneViewModel: SceneViewModel
        
        init(_ sceneViewModel: SceneViewModel) {
            self.sceneViewModel = sceneViewModel
        }
        
        func splitViewController(_ svc: UISplitViewController, willShow column: UISplitViewController.Column) {
            guard column == .primary, UIApplication.shared.applicationState == .active else { return }
            sceneViewModel.showSidebar(content: nil)
        }
        
        func splitViewController(_ svc: UISplitViewController, willHide column: UISplitViewController.Column) {
            guard column == .primary, UIApplication.shared.applicationState == .active else { return }
            sceneViewModel.hideSidebar()
        }
    }
}

@available(iOS 14.0, *)
private struct SheetView: View {
    @Binding var isSheetPresented: Bool
    
    var body: some View {
        NavigationView {
            OutlineView(isSheetPresented: $isSheetPresented).toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { isSheetPresented = false }
                }
            }.navigationBarTitle("Outline", displayMode: .inline)
        }
    }
}

@available(iOS 14.0, *)
struct SidebarView: View {
    @EnvironmentObject var sceneViewModel: SceneViewModel
    
    var body: some View {
        switch sceneViewModel.sidebarContentMode {
        case .bookmark:
            Text("bookmark!")
        case .outline:
            OutlineView(isSheetPresented: .constant(false))
        }
    }
}

@available(iOS 14.0, *)
struct ContentView: View {
    @EnvironmentObject var sceneViewModel: SceneViewModel
    
    var body: some View {
        switch sceneViewModel.contentDisplayMode {
        case .home:
            HomeView()
        case .web:
            WebView()
        case .transition:
            Color(.systemBackground)
        }
    }
}
