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
    
    private let sidebarAnimation = Animation.easeOut(duration: 0.2)
    private let sidebarWidth: CGFloat = 320.0
    
    let homeView = HomeView()
    @State var showSidebar = false
    
    var body: some View {
        if horizontalSizeClass == .regular {
            ZStack {
                homeView
                Color(UIColor.black)
                    .edgesIgnoringSafeArea(.all)
                    .opacity(colorScheme == .dark ? 0.3 : 0.1)
                    .opacity(showSidebar ? 1.0 : 0.0)
                    .animation(sidebarAnimation)
                    .onTapGesture { showSidebar.toggle() }
                HStack {
                    ZStack(alignment: .trailing) {
                        SidebarView()
                        Divider()
                    }
                    .frame(width: sidebarWidth)
                    .offset(x: showSidebar ? 0 : -sidebarWidth)
                    .animation(sidebarAnimation)
                    Spacer()
                }
            }.toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 12) {
                        SwiftUIBarButton(iconName: "chevron.left")
                        SwiftUIBarButton(iconName: "chevron.right")
                        SwiftUIBarButton(iconName: "bookmark") { self.showSidebar.toggle() }
                        SwiftUIBarButton(iconName: "clock.arrow.circlepath")
                    }.padding(.trailing, 20)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        SwiftUIBarButton(iconName: "list.bullet")
                        SwiftUIBarButton(iconName: "die.face.5")
                        SwiftUIBarButton(iconName: "map")
                        SwiftUIBarButton(iconName: "house")
                    }.padding(.leading, 20)
                }
            }
        } else {
            homeView.toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    SwiftUIBarButton(iconName: "chevron.left")
                    Spacer()
                    SwiftUIBarButton(iconName: "chevron.right")
                }
                ToolbarItem(placement: .bottomBar) { Spacer() }
                ToolbarItemGroup(placement: .bottomBar) {
                    SwiftUIBarButton(iconName: "bookmark") { self.showSidebar.toggle() }
                    Spacer()
                    SwiftUIBarButton(iconName: "list.bullet")
                    Spacer()
                    SwiftUIBarButton(iconName: "die.face.5")
                    Spacer()
                    SwiftUIBarButton(iconName: "house")
                }
            }
        }
    }
}

@available(iOS 14.0, *)
struct SwiftUIBarButton: View {
    let iconName: String
    var action: (() -> Void)?
    
    var body: some View {
        Button(action: {
            action?()
        }) {
            ZStack(alignment: .center) {
//                Color(.systemGreen).cornerRadius(6)
                Image(systemName: iconName)
                    .font(Font.body.weight(.regular))
                    .imageScale(.large)
            }.frame(width: 32, height: 32)
        }
    }
}

@available(iOS 14.0, *)
class RootController_iOS14: UIHostingController<RootView>, UISearchControllerDelegate {
    let searchController: UISearchController
    private let searchResultsController: SearchResultsController

    init() {
        self.searchResultsController = SearchResultsController()
        self.searchController = UISearchController(searchResultsController: self.searchResultsController)

        super.init(rootView: RootView())

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

