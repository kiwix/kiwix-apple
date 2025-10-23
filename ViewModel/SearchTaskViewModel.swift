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
                debugPrint("searchText: \(searchText), zimFiles: \(zimFiles.count)")
//                Task { @ZimActor [weak self] in
//                    self?.updateSearchResults(searchText, Set(zimFiles.keys))
//                }
                // TODO: move it to implementation:
                Task {
                    await MainActor.run { [weak self] in
                        self?.inProgress = false
                    }
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
    
}
