// This file is part of Kiwix for iOS & macOS.
//
// Kiwix is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// any later version.
//
// Kiwix is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Kiwix; If not, see https://www.gnu.org/licenses/.

import Combine
import CoreData
import Defaults

@MainActor
final class SearchTaskViewModel: NSObject, ObservableObject, @MainActor NSFetchedResultsControllerDelegate {
    @Published var searchText: String = ""  // text in the search field
    @Published private(set) var zimFiles: [UUID: ZimFile]  // ID of zim files that are included in search
    @Published private(set) var inProgress = false
    @Published private(set) var results: SearchResultItems = .results([])
    
    @MainActor
    static let shared = SearchTaskViewModel()
    
    private let fetchedResultsController: NSFetchedResultsController<ZimFile>
    private var searchSubscriber: AnyCancellable?
    private let dispatchQueue = DispatchQueue(label: "search", qos: .utility)
    private var task: Task<SearchResultItems, Error>?
    
    override private init() {
        // initialize fetched results controller
        let predicate = NSPredicate(
            format: "includedInSearch == true AND fileURLBookmark != nil"
        )
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: ZimFile.fetchRequest(predicate: predicate),
            managedObjectContext: Database.shared.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        // initialize zim file IDs
        try? fetchedResultsController.performFetch()
        zimFiles = fetchedResultsController.fetchedObjects?.reduce(into: [:]) { result, zimFile in
            result?[zimFile.fileID] = zimFile
        } ?? [:]
        
        super.init()
        
        fetchedResultsController.delegate = self
        
        // subscribers
        searchSubscriber = Publishers.CombineLatest(
            $searchText.removeDuplicates { prev, current in
                // consider search text to be the same ignoring spaces
                prev.trimmingCharacters(in: .whitespaces) == current.trimmingCharacters(in: .whitespaces)
            }, $zimFiles)
        .map { [unowned self] searchText, zimFiles in
            self.inProgress = true
            return (searchText, zimFiles)
        }
        .debounce(for: 0.2, scheduler: dispatchQueue)
        .sink { [weak self] searchText, zimFiles in
            Task { @MainActor [weak self] in
                self?.updateSearchTask(searchText, Set(zimFiles.keys))
                if let task = self?.task, task.isCancelled == false {
                    if let searchResults = try? await task.value {
                        self?.results = searchResults
                    }
                }
                self?.inProgress = false
            }
        }
    }
    
    deinit {
        searchSubscriber?.cancel()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        zimFiles = fetchedResultsController.fetchedObjects?.reduce(into: [:]) { result, zimFile in
            result?[zimFile.fileID] = zimFile
        } ?? [:]
    }
    
    private func updateSearchTask(_ searchText: String, _ zimFileIDs: Set<UUID>) {
        task?.cancel()
        task = Task(name: "search", priority: .utility, operation: {
            await searchResultItems(searchText, zimFileIDs)
        })
    }
    
    @ZimActor
    private func searchResultItems(_ searchText: String, _ zimFileIDs: Set<UUID>) async -> SearchResultItems {
        debugPrint("searchText: \(searchText), zimFiles: \(zimFileIDs.count)")
        guard !searchText.isEmpty else {
            return SearchResultItems.results([])
        }
        
        
        // This is run at app start, and opens the archive of all searchable ZIM files
        let cacheDir: URL? = if FeatureFlags.suggestSearchTerms {
            try? FileManager.default.url(
                for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true
            )
        } else {
            nil // don't use suggest search terms
        }
        for zimFileID in zimFileIDs {
            _ = ZimFileService.shared.openArchive(zimFileID: zimFileID)
            if let cacheDir {
                ZimFileService.shared.createSpellingIndex(zimFileID: zimFileID, cacheDir: cacheDir)
            }
        }
        let operation = SearchOperation(searchText: searchText, zimFileIDs: zimFileIDs, withSpellingCacheDir: cacheDir)
        operation.extractMatchingSnippet = Defaults[.searchResultSnippetMode] == .matches
        operation.main()
        return operation.searchResultItems
//        return SearchResultItems.results([])
    }
    
}
