//
//  SearchResultsView.swift
//  Kiwix
//
//  Created by Chris Li on 5/14/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import Combine
import SwiftUI
import RealmSwift

@available(iOS 14.0, *)
class SearchResultsHostingController: UIHostingController<AnyView>, UISearchResultsUpdating {
    private var viewModel = ViewModel()
    private var queue = OperationQueue()
    
    init() {
        super.init(rootView: AnyView(SearchResultsView().environmentObject(viewModel)))
        queue.maxConcurrentOperationCount = 1
    }
    
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.searchTextPublisher.send(searchController.searchBar.text ?? "")
    }
}

@available(iOS 14.0, *)
private class ViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var inProgress = false
    @Published var results = [SearchResult]()
    @ObservedResults(
        ZimFile.self,
        configuration: Realm.defaultConfig,
        filter: NSPredicate(format: "stateRaw == %@", ZimFile.State.onDevice.rawValue),
        sortDescriptor: SortDescriptor(keyPath: "size", ascending: false)
    ) var zimFiles
    
    var searchTextPublisher = CurrentValueSubject<String, Never>("")
    private var searchObserver: AnyCancellable?
    private var queue = OperationQueue()
    
    init() {
        queue.maxConcurrentOperationCount = 1
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "stateRaw == %@", ZimFile.State.onDevice.rawValue),
                NSPredicate(format: "includedInSearch == true"),
            ])
            searchObserver = database.objects(ZimFile.self).filter(predicate)
                .collectionPublisher
                .freeze()
                .map { zimFiles in return Array(zimFiles.map({ $0.fileID })) }
                .catch { _ in Just([]) }
                .combineLatest(searchTextPublisher)
                .sink { zimFileIDs, searchText in
                    self.updateSearchResults(searchText, Set(zimFileIDs))
                }
        } catch { }
    }
    
    private func updateSearchResults(_ searchText: String, _ zimFileIDs: Set<String>) {
        self.searchText = searchText
        inProgress = true
        
        queue.cancelAllOperations()
        let operation = SearchOperation(searchText: searchText, zimFileIDs: zimFileIDs)
        operation.completionBlock = { [weak self] in
            guard !operation.isCancelled else { return }
            DispatchQueue.main.sync {
                self?.results = operation.results
                self?.inProgress = false
            }
        }
        queue.addOperation(operation)
    }
}

@available(iOS 14.0, *)
private struct SearchResultsView: View {
    @EnvironmentObject var viewModel: ViewModel
    
    var body: some View {
        if viewModel.searchText.count == 0 {
            SearchFilterView()
        } else if viewModel.inProgress {
            Text("In Progress")
        } else if viewModel.results.isEmpty {
            Text("No Results")
        } else {
            Text(viewModel.searchText)
        }
    }
}


@available(iOS 14.0, *)
private struct SearchFilterView: View {
//    @ObservedResults(
//        ZimFile.self,
//        configuration: Realm.defaultConfig,
//        filter: NSPredicate(format: "stateRaw == %@", ZimFile.State.onDevice.rawValue),
//        sortDescriptor: SortDescriptor(keyPath: "size", ascending: false)
//    ) private var zimFiles
    
    @EnvironmentObject var viewModel: ViewModel
    
    var body: some View {
        List {
            if viewModel.zimFiles.count > 0 {
                Section(header: Text("Search Filter")) {
                    ForEach(viewModel.zimFiles) { zimFile in
                        Button(action: { }, label: {
                            ZimFileCell(zimFile, accessories: [.includedInSearch])
                        })
                    }
                }
            }
        }.listStyle(GroupedListStyle())
    }
}
