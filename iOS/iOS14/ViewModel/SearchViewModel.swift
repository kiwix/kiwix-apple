//
//  SearchViewModel.swift
//  Kiwix
//
//  Created by Chris Li on 10/27/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import SwiftUI

@available(iOS 14.0, *)
class SearchViewModel: NSObject, ObservableObject, UISearchBarDelegate {
    let searchBar = UISearchBar()
    private let searchQueue = SearchQueue()
    
    @Published private(set) var isSearchActive = false
    @Published private(set) var searchText = ""
    
    override init() {
        super.init()
        searchBar.autocorrectionType = .no
        searchBar.autocapitalizationType = .none
        searchBar.delegate = self
        searchBar.placeholder = "Search"
        searchBar.searchBarStyle = .minimal
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        withAnimation {
            isSearchActive = true
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
//        searchQueue.cancelAllOperations()
//        let operation = SearchOperation(searchText: searchText, zimFileIDs: Set())
//        operation.completionBlock = { [weak self] in
//            guard !operation.isCancelled else { return }
//            DispatchQueue.main.sync {
//                print("search finished")
//            }
//        }
//        searchQueue.addOperation(operation)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        withAnimation {
            isSearchActive = false
            searchBar.endEditing(true)
            searchBar.text = nil
        }
    }
}
