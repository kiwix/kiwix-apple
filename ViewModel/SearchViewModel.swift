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

enum SearchResultItems {
    case results([SearchResult])
    case suggestions([String])
    
    func firstIndex(where value: String) -> Int? {
        switch self {
        case let .results(results):
            results.firstIndex(where: { $0.url.absoluteString == value })
        case let .suggestions(suggestions):
            suggestions.firstIndex(where: { $0 == value})
        }
    }
    
    func index(before i: Int) -> Int {
        switch self {
        case let .results(results):
            results.index(before: i)
        case let .suggestions(suggestions):
            suggestions.index(before: i)
        }
    }
    
    func index(after i: Int) -> Int {
        switch self {
        case let .results(results):
            results.index(after: i)
        case let .suggestions(suggestions):
            suggestions.index(after: i)
        }
    }
    
    var startIndex: Int {
        switch self {
        case let .results(results):
            results.startIndex
        case let .suggestions(suggestions):
            suggestions.startIndex
        }
    }
    
    var endIndex: Int {
        switch self {
        case let .results(results):
            results.endIndex
        case let .suggestions(suggestions):
            suggestions.endIndex
        }
    }
}

final class SearchViewModel: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
    @Published var searchText: String = ""  // text in the search field
    @Published private(set) var zimFiles: [UUID: ZimFile]  // ID of zim files that are included in search
    @Published private(set) var inProgress = false
    @Published private(set) var results: SearchResultItems = .results([])
    
    static let shared = SearchViewModel()

    private let fetchedResultsController: NSFetchedResultsController<ZimFile>
    private var searchSubscriber: AnyCancellable?
    @ZimActor
    private let queue = OperationQueue()

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

        // additional configurations
        queue.maxConcurrentOperationCount = 1
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
            .debounce(for: 0.2, scheduler: DispatchQueue.main)
            .sink { [unowned self] searchText, zimFiles in
                Task { @ZimActor [weak self] in
                    self?.updateSearchResults(searchText, Set(zimFiles.keys))
                }
            }
    }
    
    deinit {
        queue.cancelAllOperations()
        searchSubscriber?.cancel()
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        zimFiles = fetchedResultsController.fetchedObjects?.reduce(into: [:]) { result, zimFile in
            result?[zimFile.fileID] = zimFile
        } ?? [:]
    }

    @ZimActor
    private func updateSearchResults(_ searchText: String, _ zimFileIDs: Set<UUID>) {
        queue.cancelAllOperations()
        // This is run at app start, and opens the archive of all searchable ZIM files
        for zimFileID in zimFileIDs {
            _ = ZimFileService.shared.openArchive(zimFileID: zimFileID)
            ZimFileService.shared.createSpellingIndexFor(zimFileID: zimFileID)
        }
        let cacheDir = ZimFileService.shared.spellingCacheDir()
        let operation = SearchOperation(
            searchText: searchText,
            zimFileIDs: zimFileIDs,
            withSpellingCacheDir: cacheDir
        )
        operation.extractMatchingSnippet = Defaults[.searchResultSnippetMode] == .matches
//        operation.completionBlock = { [weak self] in
//            guard !operation.isCancelled else { return }
//            Task { @MainActor [weak self] in
//                self?.results = operation.searchResultItems
//                self?.inProgress = false
//            }
//        }
//        queue.addOperation(operation)
    }
}
