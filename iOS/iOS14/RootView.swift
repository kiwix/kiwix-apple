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
        let leadingNavBarItems = HStack(spacing: 20) {
            Button(action: {}) {
                Image(systemName: "chevron.left").font(Font.body.weight(.regular)).imageScale(.large)
            }
            Button(action: {}) {
                Image(systemName: "chevron.right").font(Font.body.weight(.regular)).imageScale(.large)
            }
            Button(action: {
                self.showSidebar.toggle()
            }) {
                Image(systemName: "bookmark").font(Font.body.weight(.regular)).imageScale(.large)
            }
            Button(action: {}) {
                Image(systemName: "clock.arrow.circlepath").font(Font.body.weight(.regular)).imageScale(.large)
            }
        }.padding(.trailing, 20)
        let trailingNavBarItems = HStack(spacing: 20) {
            Button(action: {}) {
                Image(systemName: "list.bullet").font(Font.body.weight(.regular)).imageScale(.large)
            }
            Button(action: {}) {
                Image(systemName: "die.face.5").font(Font.body.weight(.regular)).imageScale(.large)
            }
            Button(action: {}) {
                Image(systemName: "map").font(Font.body.weight(.regular)).imageScale(.large)
            }
            Button(action: {}) {
                Image(systemName: "house").font(Font.body.weight(.regular)).imageScale(.large)
            }
        }.padding(.leading, 20)
        if horizontalSizeClass == .regular {
            ZStack {
                homeView
                Color(UIColor.black)
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
            }.navigationBarItems(leading: leadingNavBarItems, trailing: trailingNavBarItems)
        } else {
            homeView.toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button(action: {}) {
                        Image(systemName: "chevron.left").font(Font.body.weight(.regular)).imageScale(.large)
                    }
                }
            }
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

