//
//  SearchViewModel.swift
//  Kiwix
//
//  Created by Chris Li on 10/27/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import SwiftUI
import RealmSwift

@available(iOS 14.0, *)
class SearchViewModel: NSObject, ObservableObject, UISearchBarDelegate {
    private let searchQueue = SearchQueue()
    private let zimFiles: Results<ZimFile>? = {
        do {
            let format = "stateRaw == %@ AND includedInSearch == true"
            let predicate = NSPredicate(format: format, ZimFile.State.onDevice.rawValue)
            let database = try Realm(configuration: Realm.defaultConfig)
            return database.objects(ZimFile.self).filter(predicate)
        } catch { return nil }
    }()
    
    let searchBar = UISearchBar()
    @Published private(set) var isSearchActive = false
    @Published private(set) var searchText = ""
    @Published private(set) var searchResults = [SearchResult]()
    
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
        guard isSearchActive else { return }
        
        let zimFileIDs: Set<String> = {
            guard let result = zimFiles else { return Set() }
            return Set(result.map({ $0.id }))
        }()
        searchQueue.cancelAllOperations()
        let operation = SearchOperation(searchText: searchText, zimFileIDs: zimFileIDs)
        operation.completionBlock = { [weak self] in
            guard !operation.isCancelled else { return }
            DispatchQueue.main.sync {
                self?.searchResults = operation.results
            }
        }
        searchQueue.addOperation(operation)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        withAnimation {
            isSearchActive = false
            searchBar.endEditing(true)
            searchBar.text = nil
        }
    }
}
