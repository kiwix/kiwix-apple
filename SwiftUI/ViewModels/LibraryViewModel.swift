//
//  LibraryViewModel.swift
//  Kiwix
//
//  Created by Chris Li on 5/22/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import CoreData
import os

import Defaults

class LibraryViewModel: ObservableObject {
    @Published private(set) var isRefreshing = false
    
    private var progressObserver: NSKeyValueObservation?
    
    static let operationQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    
    init() {
        let progress = LibraryViewModel.operationQueue.progress
        progressObserver = progress.observe(\.fractionCompleted, options: .new) { [unowned self] _, change in
            DispatchQueue.main.async {
                self.isRefreshing = change.newValue != 1
            }
        }
    }
    
    // MARK: - Refresh
    
    func startRefresh(isUserInitiated: Bool, completion: (() -> Void)? = nil) {
        guard !isRefreshing else { return }
        
        // decide if refresh should proceed
        let isStale = (Defaults[.libraryLastRefresh]?.timeIntervalSinceNow ?? -3600) <= -3600
        guard isUserInitiated || (Defaults[.libraryAutoRefresh] && isStale) else { return }
        
        // configure operation
        let operation = LibraryRefreshOperation()
        operation.completionBlock = {
            DispatchQueue.main.async {
                completion?()
            }
        }
        
        // start refresh
        isRefreshing = true
        LibraryViewModel.operationQueue.progress.totalUnitCount += 1
        LibraryViewModel.operationQueue.addOperation(operation)
    }
}

class LibraryRefreshOperation: Operation {
    private(set) var insertionCount = 0
    private(set) var deletionCount = 0
    private(set) var error: OPDSRefreshError?
    
    override func main() {
        do {
            os_log("Refresh started.", log: Log.OPDS, type: .debug)

            // perform refresh
            let data = try fetchOPDSData()
            let parser = OPDSStreamParser()
            try parser.parse(data: data)
            try processData(parser)
            
            // Update user defaults
            Defaults[.libraryLastRefresh] = Date()
            if Defaults[.libraryLanguageCodes].isEmpty, let currentLanguageCode = Locale.current.languageCode {
                Defaults[.libraryLanguageCodes] = [currentLanguageCode]
            }
            
            os_log("Refresh finished -- addition: %d, deletion: %d, total: %d",
                   log: Log.OPDS,
                   type: .default,
                   insertionCount,
                   deletionCount,
                   parser.zimFileIDs.count
            )
        } catch let error as OPDSRefreshError {
            self.error = error
            os_log("Error updating library: %s", log: Log.OPDS, type: .error, error.localizedDescription)
        } catch {
            os_log("Unknown error updating library: %s", log: Log.OPDS, type: .error, error.localizedDescription)
        }
    }
    
    /// Retrieve the whole OPDS stream from library.kiwix.org
    /// - Throws: OPDSRefreshError, the error happened during OPDS stream retrieval
    /// - Returns: Data, a data object containing the OPDS stream
    private func fetchOPDSData() throws -> Data {
        var data: Data?
        var error: Swift.Error?

        let semaphore = DispatchSemaphore(value: 0)
        let url = URL(string: "https://library.kiwix.org/catalog/root.xml")!
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)

        let dataTask = URLSession.shared.dataTask(with: request) {
            data = $0
            error = $2
            semaphore.signal()
        }

        dataTask.resume()
        semaphore.wait()

        if let data = data {
            os_log("Retrieved OPDS Stream, size: %llu bytes", log: Log.OPDS, type: .info, data.count)
            return data
        } else {
            let description = error?.localizedDescription ??
                NSLocalizedString("Unable to fetch data", comment: "Library Refresh Error")
            os_log("Error retrieving OPDS Stream: %s", log: Log.OPDS, type: .error, description)
            throw OPDSRefreshError.retrieve(description: description)
        }
    }
    
    /// Process the parsed OPDS data
    /// - Parameter parser: OPDS stream parser
    private func processData(_ parser: OPDSStreamParser) throws {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = Database.shared.container.persistentStoreCoordinator
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        context.undoManager = nil
        
        do {
            // insert new zim files
            let existing = try context.fetch(ZimFile.fetchRequest()).map { $0.fileID.uuidString.lowercased() }
            var zimFileIDs = Set(parser.zimFileIDs).subtracting(existing)
            let insertRequest = NSBatchInsertRequest(
                entity: ZimFile.entity(),
                managedObjectHandler: { zimFile in
                    guard let zimFile = zimFile as? ZimFile else { return true }
                    while !zimFileIDs.isEmpty {
                        guard let id = zimFileIDs.popFirst(),
                              let metadata = parser.getZimFileMetaData(id: id) else { continue }
                        LibraryOperations.configureZimFile(zimFile, metadata: metadata)
                        return false
                    }
                    return true
                }
            )
            insertRequest.resultType = .count
            insertionCount = (try context.execute(insertRequest) as? NSBatchInsertResult)?.result as? Int ?? 0
            
            // delete old zim files
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = ZimFile.fetchRequest()
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "fileURLBookmark == nil"),
                NSPredicate(format: "NOT fileID IN %@", parser.zimFileIDs.compactMap { UUID(uuidString: $0) })
            ])
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            deleteRequest.resultType = .resultTypeCount
            deletionCount = (try context.execute(deleteRequest) as? NSBatchDeleteResult)?.result as? Int ?? 0
        } catch {
            os_log("Error processing OPDS Stream: %s", log: Log.OPDS, type: .error, error.localizedDescription)
            throw OPDSRefreshError.process
        }
    }
}
