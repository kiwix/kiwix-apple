//
//  ViewController.swift
//  Kiwix for iOS
//
//  Created by Chris Li on 5/21/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import UIKit
import SwiftUI

@main
struct Kiwix: App {
    init() {
        reopen()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .edgesIgnoringSafeArea(.all)
                .environment(\.managedObjectContext, Database.shared.container.viewContext)
        }
    }
    
    private func reopen() {
        let context = Database.shared.container.viewContext
        let request = ZimFile.fetchRequest(predicate: NSPredicate(format: "fileURLBookmark != nil"))
        guard let zimFiles = try? context.fetch(request) else { return }
        zimFiles.forEach { zimFile in
            guard let data = zimFile.fileURLBookmark else { return }
            if let data = ZimFileService.shared.open(bookmark: data) {
                zimFile.fileURLBookmark = data
            }
        }
        if context.hasChanges {
            try? context.save()
        }
    }
}

private struct RootView: UIViewControllerRepresentable {
    @State private var isSearchActive = false
    @State private var searchText = ""
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let controller = UIHostingController(rootView: Reader(isSearchActive: $isSearchActive))
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
        let rootView: RootView
        let searchController: UISearchController
        
        init(_ rootView: RootView) {
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
            rootView.searchText = searchController.searchBar.text ?? ""
        }
    }
}
