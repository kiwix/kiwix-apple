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

public class LibraryRefreshViewModel: ObservableObject {
    @Published public private(set) var error: Error?
    
    private let urlSession: URLSession
    private let context: NSManagedObjectContext
    private var insertionCount = 0
    private var deletionCount = 0
    
    public init(urlSession: URLSession? = nil, context: NSManagedObjectContext? = nil) {
        self.urlSession = urlSession ?? URLSession.shared
        self.context = context ?? {
            let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            context.persistentStoreCoordinator = Database.shared.container.persistentStoreCoordinator
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            context.undoManager = nil
            return context
        }()
    }
    
    public func start(isUserInitiated: Bool) async {
        do {
            // decide if refresh should proceed
            let isStale = (Defaults[.libraryLastRefresh]?.timeIntervalSinceNow ?? -3600) <= -3600
            guard isUserInitiated || (Defaults[.libraryAutoRefresh] && isStale) else { return }
            
            // refresh library
            guard let data = try await fetchData() else { return }
            let parser = try await parse(data: data)
            try await process(parser: parser)
            
            // update library last refresh timestamp
            Defaults[.libraryLastRefresh] = Date()
            
            // populate library language code if there isn't one set already
            if Defaults[.libraryLanguageCodes].isEmpty, let currentLanguageCode = Locale.current.languageCode {
                Defaults[.libraryLanguageCodes] = [currentLanguageCode]
            }
            
            // reset error
            error = nil
            
            // logging
            os_log("Refresh finished -- addition: %d, deletion: %d, total: %d",
                   log: Log.OPDS, type: .default, insertionCount, deletionCount, parser.zimFileIDs.count)
        } catch {
            self.error = error
        }
    }
    
    private func fetchData() async throws -> Data? {
        guard let url = URL(string: "https://library.kiwix.org/catalog/root.xml") else { return nil }
        do {
            let request = URLRequest(url: url, timeoutInterval: 20)
            let (data, response) = try await self.urlSession.data(for: request)
            guard let response = response as? HTTPURLResponse else { return nil }
            guard response.statusCode == 200 else {
                throw LibraryRefreshError.retrieve(description: "HTTP Status \(response.statusCode).")
            }
            os_log("Retrieved OPDS Data, size: %llu bytes", log: Log.OPDS, type: .info, data.count)
            return data
        } catch {
            os_log("Error retrieving OPDS Data: %s", log: Log.OPDS, type: .error)
            if let error = error as? LibraryRefreshError {
                throw error
            } else {
                throw LibraryRefreshError.retrieve(description: error.localizedDescription)
            }
        }
    }
    
    private func parse(data: Data) async throws -> OPDSParser {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global().async {
                let parser = OPDSParser()
                do {
                    try parser.parse(data: data)
                    continuation.resume(returning: parser)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func process(parser: OPDSParser) async throws {
        try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    // insert new zim files
                    let existing = try self.context.fetch(ZimFile.fetchRequest()).map { $0.fileID }
                    var zimFileIDs = parser.zimFileIDs.subtracting(existing)
                    let insertRequest = NSBatchInsertRequest(
                        entity: ZimFile.entity(),
                        managedObjectHandler: { zimFile in
                            guard let zimFile = zimFile as? ZimFile else { return true }
                            while !zimFileIDs.isEmpty {
                                guard let id = zimFileIDs.popFirst(),
                                      let metadata = parser.getMetaData(id: id) else { continue }
                                LibraryOperations.configureZimFile(zimFile, metadata: metadata)
                                return false
                            }
                            return true
                        }
                    )
                    insertRequest.resultType = .count
                    if let result = try self.context.execute(insertRequest) as? NSBatchInsertResult {
                        self.insertionCount = result.result as? Int ?? 0
                    }
                    
                    // delete old zim files
                    let fetchRequest: NSFetchRequest<NSFetchRequestResult> = ZimFile.fetchRequest()
                    fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                        NSPredicate(format: "fileURLBookmark == nil"),
                        NSPredicate(format: "NOT fileID IN %@", parser.zimFileIDs)
                    ])
                    let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                    deleteRequest.resultType = .resultTypeCount
                    if let result = try self.context.execute(deleteRequest) as? NSBatchDeleteResult {
                        self.deletionCount = result.result as? Int ?? 0
                    }
                    
                    continuation.resume()
                } catch {
                    os_log("Error saving OPDS Data: %s", log: Log.OPDS, type: .error, error.localizedDescription)
                    continuation.resume(throwing: LibraryRefreshError.process)
                }
            }
        }
    }
}

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
    private(set) var error: LibraryRefreshError?
    
    override func main() {
        do {
            os_log("Refresh started.", log: Log.OPDS, type: .debug)

            // perform refresh
            let data = try fetchOPDSData()
            let parser = OPDSParser()
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
        } catch let error as LibraryRefreshError {
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
            throw LibraryRefreshError.retrieve(description: description)
        }
    }
    
    /// Process the parsed OPDS data
    /// - Parameter parser: OPDS parser
    private func processData(_ parser: OPDSParser) throws {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = Database.shared.container.persistentStoreCoordinator
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        context.undoManager = nil
        
        do {
            // insert new zim files
            let existing = try context.fetch(ZimFile.fetchRequest()).map { $0.fileID }
            var zimFileIDs = parser.zimFileIDs.subtracting(existing)
            let insertRequest = NSBatchInsertRequest(
                entity: ZimFile.entity(),
                managedObjectHandler: { zimFile in
                    guard let zimFile = zimFile as? ZimFile else { return true }
                    while !zimFileIDs.isEmpty {
                        guard let id = zimFileIDs.popFirst(),
                              let metadata = parser.getMetaData(id: id) else { continue }
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
                NSPredicate(format: "NOT fileID IN %@", parser.zimFileIDs)
            ])
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            deleteRequest.resultType = .resultTypeCount
            deletionCount = (try context.execute(deleteRequest) as? NSBatchDeleteResult)?.result as? Int ?? 0
        } catch {
            os_log("Error processing OPDS Stream: %s", log: Log.OPDS, type: .error, error.localizedDescription)
            throw LibraryRefreshError.process
        }
    }
}
