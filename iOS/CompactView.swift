//
//  CompactView.swift
//  Kiwix
//
//  Created by Chris Li on 7/30/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import CoreData
import SwiftUI

@available(iOS 16.0, *)
struct CompactView: UIViewControllerRepresentable {
    @EnvironmentObject private var navigation: NavigationViewModel
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let controller = UINavigationController()
        controller.isToolbarHidden = false
        controller.toolbar.scrollEdgeAppearance = {
            let apperance = UIToolbarAppearance()
            apperance.configureWithDefaultBackground()
            return apperance
        }()
        return controller
    }
    
    func updateUIViewController(_ navigationController: UINavigationController, context: Context) {
        let controller: CompactViewController<AnyView> = {
            if case let .tab(tabID) = navigation.currentItem {
                return CompactViewController(rootView: AnyView(BrowserTabCompact(tabID: tabID)))
            } else {
                return CompactViewController(rootView: AnyView(EmptyView()))
            }
        }()
        controller.navigationItem.scrollEdgeAppearance = {
            let apperance = UINavigationBarAppearance()
            apperance.configureWithDefaultBackground()
            return apperance
        }()
        navigationController.viewControllers = [controller]
    }
}

private class CompactViewController<Content>: UIHostingController<Content>,
                                              UISearchResultsUpdating, UISearchControllerDelegate where Content: View {
    private let searchController: UISearchController
    private let searchViewModel = SearchViewModel()
    
    override init(rootView: Content) {
        let searchResults = SearchResults().environmentObject(searchViewModel)
        searchController = UISearchController(searchResultsController: UIHostingController(rootView: searchResults))
        super.init(rootView: rootView)
    }
    
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        definesPresentationContext = true

        // configure search
        searchController.delegate = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchResultsUpdater = self
        searchController.showsSearchResultsController = true
        navigationItem.titleView = searchController.searchBar
        
        NotificationCenter.default.addObserver(self, selector: #selector(onOpenURL), name: .openURL, object: nil)
    }

    func willPresentSearchController(_ searchController: UISearchController) {
        guard traitCollection.horizontalSizeClass == .compact,
              UIDevice.current.userInterfaceIdiom == .pad else { return }
        navigationController?.setToolbarHidden(true, animated: true)
        navigationItem.setRightBarButton(
            UIBarButtonItem(systemItem: .cancel, primaryAction: UIAction { _ in
                searchController.isActive = false
            }), animated: true
        )
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        navigationController?.setToolbarHidden(false, animated: true)
        navigationItem.setRightBarButton(nil, animated: true)
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        guard searchController.isActive else { return }
        searchViewModel.searchText = searchController.searchBar.text ?? ""
    }
        
    @objc func onOpenURL() {
        searchController.isActive = false
    }
}
