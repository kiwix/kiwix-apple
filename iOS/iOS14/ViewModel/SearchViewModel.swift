//
//  SearchViewModel.swift
//  Kiwix
//
//  Created by Chris Li on 10/27/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import Combine
import SwiftUI
import RealmSwift

@available(iOS 14.0, *)
enum SearchViewContent {
    case initial, inProgress, results, noResult
}

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
    private var zimFilesObserver: AnyCancellable?
    
    @Published var rawSearchText = ""
    private var rawSearchTextDebouncer: AnyCancellable?
    
    @Published private(set) var recentSearchTexts: [String] = []
    private var recentSearchTextsObserver: AnyCancellable?
    
    let searchBar = UISearchBar()
    private let animation = Animation.easeInOut(duration: 0.05)
    @Published private(set) var isActive = false
    @Published private(set) var content: SearchViewContent = .initial
    @Published private(set) var results = [SearchResult]()

    override init() {
        self.recentSearchTexts = []
        super.init()
        searchBar.autocorrectionType = .no
        searchBar.autocapitalizationType = .none
        searchBar.delegate = self
        searchBar.placeholder = "Search"
        searchBar.searchBarStyle = .minimal
        
        self.zimFilesObserver = zimFiles?.collectionPublisher.sink(
            receiveCompletion: { _ in },
            receiveValue: { _ in self.search(self.rawSearchText) }
        )
        self.rawSearchTextDebouncer = $rawSearchText
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .removeDuplicates { $0 == $1 }
            .sink { self.search($0) }
        self.recentSearchTextsObserver = UserDefaults.standard
            .publisher(for: \.recentSearchTexts)
            .assign(to: \.recentSearchTexts, on: self)
    }
    
    func updateRecentSearchText() {
        var searchTexts = UserDefaults.standard.stringArray(forKey: "recentSearchTexts") ?? [String]()
        searchTexts.removeAll { $0 == rawSearchText }
        searchTexts.insert(rawSearchText, at: 0)
        UserDefaults.standard.setValue(Array(searchTexts.prefix(20)), forKey: "recentSearchTexts")
    }
    
    func cancelSearch() {
        searchQueue.cancelAllOperations()
        withAnimation(animation)  {
            rawSearchText = ""
            isActive = false
            content = .initial
            results = []
            searchBar.endEditing(true)
            searchBar.text = nil
        }
    }
    
    private func search(_ text: String) {
        searchQueue.cancelAllOperations()
        if text.isEmpty {
            withAnimation(animation) { content = .initial }
        } else {
            withAnimation(animation) { content = .inProgress }
            let zimFileIDs: Set<String> = {
                guard let result = zimFiles else { return Set() }
                return Set(result.map({ $0.id }))
            }()
            let operation = SearchOperation(searchText: text, zimFileIDs: zimFileIDs)
            operation.completionBlock = { [weak self] in
                guard !operation.isCancelled else { return }
                DispatchQueue.main.sync {
                    withAnimation(self?.animation ?? Animation.default)  {
                        self?.results = operation.results
                        self?.content = operation.results.isEmpty ? .noResult : .results
                    }
                }
            }
            searchQueue.addOperation(operation)
        }
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        withAnimation(animation)  {
            isActive = true
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.rawSearchText = searchText
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        search(rawSearchText)
    }
}
