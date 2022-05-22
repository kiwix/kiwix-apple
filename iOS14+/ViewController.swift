//
//  ViewController.swift
//  iOS14+
//
//  Created by Chris Li on 5/21/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import UIKit
import SwiftUI

class ViewController: UIHostingController<Reader>, UISearchControllerDelegate {
    let searchController = UISearchController()
    
    convenience init() {
        self.init(rootView: Reader())
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureSearch()
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
        rootView.viewModel.cancelSearch = {[unowned self] in self.searchController.isActive = false }
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

struct Reader: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @ObservedObject var viewModel = ReaderViewModel()
    
    var body: some View {
        if viewModel.isSearchActive {
            Text("Hello!").toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { viewModel.cancelSearch?()}
                }
            }
        } else if horizontalSizeClass == .regular {
            Text("Hello!").toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button { } label: { Image(systemName: "chevron.left") }
                    Button { } label: { Image(systemName: "chevron.right") }
                    Button { } label: { Image(systemName: "list.bullet") }
                    Button { } label: { Image(systemName: "star") }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button { } label: { Image(systemName: "die.face.5") }
                    Button { } label: { Image(systemName: "house") }
                    Button { } label: { Image(systemName: "folder") }
                    Button { } label: { Image(systemName: "gear") }
                }
            }
        } else {
            Text("Hello!").toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Group {
                        Button { } label: { Image(systemName: "chevron.left") }
                        Spacer()
                        Button { } label: { Image(systemName: "chevron.right") }
                    }
                    Spacer()
                    Group {
                        Button { } label: { Image(systemName: "list.bullet") }
                        Spacer()
                        Button { } label: { Image(systemName: "star") }
                        Spacer()
                        Button { } label: { Image(systemName: "die.face.5") }
                    }
                    Spacer()
                    Menu {
                        Button { } label: { Label("Main Page", systemImage: "house") }
                        Button { } label: { Label("Library", systemImage: "folder") }
                        Button { } label: { Label("Settings", systemImage: "gear") }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
}

class ReaderViewModel: ObservableObject {
    @Published var isSearchActive: Bool = false
    
    var cancelSearch: (() -> Void)?
}
