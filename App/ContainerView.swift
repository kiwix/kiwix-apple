//
//  ContainerView.swift
//  Kiwix
//
//  Created by Chris Li on 8/16/23.
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
#endif
