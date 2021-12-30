//
//  Search.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 11/6/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import Combine
import CoreData
import SwiftUI

import Defaults

/// Search interface in the sidebar.
struct Search: View {
    @Binding var url: URL?
    @State private var selectedSearchText: String?
    @StateObject private var viewModel = ViewModel()
    @Default(.recentSearchTexts) private var recentSearchTexts: [String]
    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "fileURLBookmark != nil")
    ) private var zimFiles: FetchedResults<ZimFile>
    
    var body: some View {
        SearchField(searchText: $viewModel.searchText).padding(.horizontal, 10).padding(.vertical, 6)
        searchResults
        searchFilter
    }
    
    @ViewBuilder
    var searchResults: some View {
        if viewModel.searchText.isEmpty, !recentSearchTexts.isEmpty {
            List(recentSearchTexts, id: \.self, selection: $selectedSearchText) { searchText in
                Text(searchText)
            }.onChange(of: selectedSearchText) { self.updateCurrentSearchText($0) }
        } else if !viewModel.searchText.isEmpty, !viewModel.results.isEmpty {
            List(viewModel.results, id: \.url, selection: $url) { searchResult in
                Text(searchResult.title)
            }.onChange(of: url) { _ in self.updateRecentSearchTexts(viewModel.searchText) }
        } else if !viewModel.searchText.isEmpty, viewModel.results.isEmpty, !viewModel.inProgress {
            List { Text("No Result") }
        } else {
            List { }
        }
    }
    
    @ViewBuilder
    var searchFilter: some View {
        Divider()
        HStack {
            Text("Include in Search").fontWeight(.medium)
            Spacer()
            if zimFiles.map {$0.includedInSearch }.reduce(true) { $0 && $1 } {
                Button { selectNoZimFiles() } label: {
                    Text("None").font(.caption).fontWeight(.medium)
                }
            } else {
                Button { selectAllZimFiles() } label: {
                    Text("All").font(.caption).fontWeight(.medium)
                }
            }
        }.padding(.vertical, 5).padding(.leading, 16).padding(.trailing, 10).background(.regularMaterial)
        Divider()
        List(zimFiles) { zimFile in
            Toggle(zimFile.name, isOn: Binding<Bool>(get: {
                zimFile.includedInSearch
            }, set: {
                zimFile.includedInSearch = $0
                try? managedObjectContext.save()
            }))
        }.frame(height: 150)
    }
    
    private func updateCurrentSearchText(_ searchText: String?) {
        guard let searchText = searchText else { return }
        viewModel.searchText = searchText
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            selectedSearchText = nil
        }
    }
    
    private func updateRecentSearchTexts(_ searchText: String) {
        guard !searchText.isEmpty else { return }
        var recentSearchTexts = self.recentSearchTexts
        recentSearchTexts.removeAll { $0 == searchText }
        recentSearchTexts.insert(searchText, at: 0)
        self.recentSearchTexts = recentSearchTexts
    }
    
    private func selectAllZimFiles() {
        let request = ZimFile.fetchRequest()
        try? managedObjectContext.fetch(request).forEach { zimFile in
            zimFile.includedInSearch = true
        }
        try? managedObjectContext.save()
    }
    
    private func selectNoZimFiles() {
        let request = ZimFile.fetchRequest()
        try? managedObjectContext.fetch(request).forEach { zimFile in
            zimFile.includedInSearch = false
        }
        try? managedObjectContext.save()
    }
}

private class ViewModel: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
    @Published var searchText: String = ""  // text in the search field
    @Published private var zimFileIDs: [UUID]  // ID of zim files that are included in search
    @Published private(set) var inProgress = false
    @Published private(set) var results = [SearchResult]()
    
    private let fetchedResultsController: NSFetchedResultsController<ZimFile>
    private var searchSubscriber: AnyCancellable?
    private var searchTextSubscriber: AnyCancellable?
    private let queue = OperationQueue()
    
    override init() {
        // initilize fetched results controller
        let predicate = NSPredicate(format: "includedInSearch == true AND fileURLBookmark != nil")
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: ZimFile.fetchRequest(predicate: predicate),
            managedObjectContext: Database.shared.container.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        // initilze zim file IDs
        try? fetchedResultsController.performFetch()
        zimFileIDs = fetchedResultsController.fetchedObjects?.map { $0.fileID } ?? []
        
        super.init()
        
        // additional configurations
        queue.maxConcurrentOperationCount = 1
        fetchedResultsController.delegate = self
        
        // subscribers
        searchSubscriber = Publishers.CombineLatest($zimFileIDs, $searchText)
            .debounce(for: 0.2, scheduler: queue, options: nil)
            .receive(on: DispatchQueue.main, options: nil)
            .sink { zimFileIDs, searchText in
                self.updateSearchResults(searchText, Set(zimFileIDs))
            }
        searchTextSubscriber = $searchText.sink { searchText in self.inProgress = true }
    }
    
    private func updateSearchResults(_ searchText: String, _ zimFileIDs: Set<UUID>) {
        queue.cancelAllOperations()
        let zimFileIDs = Set(zimFileIDs.map { $0.uuidString.lowercased() })
        let operation = SearchOperation(searchText: searchText, zimFileIDs: zimFileIDs)
        operation.completionBlock = { [unowned self] in
            guard !operation.isCancelled else { return }
            DispatchQueue.main.sync {
                self.results = operation.results
                self.inProgress = false
            }
        }
        queue.addOperation(operation)
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        zimFileIDs = fetchedResultsController.fetchedObjects?.map { $0.fileID } ?? []
    }
}
