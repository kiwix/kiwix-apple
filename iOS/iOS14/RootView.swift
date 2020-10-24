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
    @State private var sidebarDisplayMode = SidebarDisplayMode.hidden
    @State private var showSidebar = false
    
    private let sidebarAnimation = Animation.easeOut(duration: 0.2)
    private let sidebarWidth: CGFloat = 320.0
    
    var content: some View {
        ZStack {
            switch sceneViewModel.contentDisplayMode {
            case .homeView:
                HomeView()
            case .webView:
                WebView()
            case .transitionView:
                Color(.systemBackground)
            }
            if horizontalSizeClass == .regular {
                Color(UIColor.black)
                    .edgesIgnoringSafeArea(.all)
                    .opacity(colorScheme == .dark ? 0.3 : 0.1)
                    .opacity(showSidebar ? 1.0 : 0.0)
                    .onTapGesture { hideSideBar() }
                HStack {
                    ZStack(alignment: .trailing) {
                        SidebarView()
                        Divider()
                    }
                    .frame(width: sidebarWidth)
                    .offset(x: showSidebar ? 0 : -sidebarWidth)
                    Spacer()
                }
            }
        }
    }
    
    var body: some View {
        if horizontalSizeClass == .regular {
            content.toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    GoBackButton()
                    GoForwardButton()
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 12) {
                        SwiftUIBarButton(iconName: "bookmark") { showSidebar ? hideSideBar() : showBookmark() }
                        SwiftUIBarButton(iconName: "clock.arrow.circlepath") { showSidebar ? hideSideBar() : showRecent() }
                    }.padding(.trailing, 20)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        SwiftUIBarButton(iconName: "die.face.5")
                        SwiftUIBarButton(iconName: "list.bullet")
                        SwiftUIBarButton(iconName: "map")
                        
                    }.padding(.leading, 20)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    ZStack {
                        Spacer()
                        HouseButton()
                    }
                }
            }
        } else if horizontalSizeClass == .compact {
            content.toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    GoBackButton()
                    Spacer()
                    GoForwardButton()
                }
                ToolbarItem(placement: .bottomBar) { Spacer() }
                ToolbarItemGroup(placement: .bottomBar) {
                    SwiftUIBarButton(iconName: "bookmark") { showBookmark() }
                    Spacer()
                    SwiftUIBarButton(iconName: "list.bullet")
                    Spacer()
                    SwiftUIBarButton(iconName: "die.face.5")
                }
                ToolbarItem(placement: .bottomBar) { Spacer() }
                ToolbarItem(placement: .bottomBar) {
                    ZStack {
                        Spacer()
                        HouseButton()
                    }
                }
            }
        }
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
class RootController_iOS14: UIHostingController<AnyView>, UISearchControllerDelegate {
    private let searchController: UISearchController
    private let searchResultsController: SearchResultsController
    private let sceneViewModel = SceneViewModel()

    init() {
        self.searchResultsController = SearchResultsController()
        self.searchController = UISearchController(searchResultsController: self.searchResultsController)

        super.init(rootView: AnyView(RootView().environmentObject(sceneViewModel)))

        // search controller
        searchController.delegate = self
        searchController.searchBar.autocorrectionType = .no
        searchController.searchBar.autocapitalizationType = .none
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchResultsUpdater = searchResultsController
        searchController.automaticallyShowsCancelButton = false
        searchController.showsSearchResultsController = true

        // misc
        definesPresentationContext = true
        navigationItem.hidesBackButton = true
        navigationItem.titleView = searchController.searchBar
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

