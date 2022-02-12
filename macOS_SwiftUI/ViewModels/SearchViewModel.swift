//
//  SearchViewModel.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 2/12/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import Combine
import CoreData

class SearchViewModel: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
    @Published var searchText: String = ""  // text in the search field
    @Published private(set) var zimFileIDs: [UUID]  // ID of zim files that are included in search
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
