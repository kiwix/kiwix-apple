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
    func makeUIViewController(context: Context) -> UINavigationController {
        UINavigationController(rootViewController: RootViewController())
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) { }
}

private class RootViewController: UIHostingController<Reader>, UISearchControllerDelegate {
    let searchController = UISearchController()
    
    convenience init() {
        self.init(rootView: Reader())
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureSearch()
        
        if #available(iOS 15.0, *) {
            navigationItem.scrollEdgeAppearance = {
                let apperance = UINavigationBarAppearance()
                apperance.configureWithDefaultBackground()
                return apperance
            }()
            navigationController?.toolbar.scrollEdgeAppearance = {
                let apperance = UIToolbarAppearance()
                apperance.configureWithDefaultBackground()
                return apperance
            }()
        }
    }
    
    private func configureSearch() {
        searchController.delegate = self
        searchController.searchBar.autocorrectionType = .no
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.searchBarStyle = .minimal
        searchController.hidesNavigationBarDuringPresentation = false
//        searchController.searchResultsUpdater = searchResultsController
        searchController.automaticallyShowsCancelButton = false
        searchController.showsSearchResultsController = true
//        rootView.viewModel.cancelSearch = {[unowned self] in self.searchController.isActive = false }
        definesPresentationContext = true
        navigationItem.titleView = searchController.searchBar
    }
    
    // MARK: - UISearchControllerDelegate
    
    func willPresentSearchController(_ searchController: UISearchController) {
        rootView.viewModel.isSearchActive = true
    }

    func willDismissSearchController(_ searchController: UISearchController) {
        rootView.viewModel.isSearchActive = false
    }
}
