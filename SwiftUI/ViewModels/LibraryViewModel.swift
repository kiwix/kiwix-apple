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
    @Published var isFileImporterPresented: Bool = false
    @Published private(set) var isRefreshing = false
    
    private var progressObserver: NSKeyValueObservation?
    
    static let backgroundTaskIdentifier = "org.kiwix.library_refresh"
    static let operationQueue = OperationQueue()
    
    init() {
        let progress = LibraryViewModel.operationQueue.progress
        isRefreshing = progress.completedUnitCount != progress.totalUnitCount
        progressObserver = progress.observe(\.fractionCompleted, options: .new) { [unowned self] _, change in
            DispatchQueue.main.async {
                print("change", change)
                self.isRefreshing = change.newValue != 1
            }
        }
    }
    
    deinit {
        print("deinit")
    }
    
    // MARK: - Refresh
    
    func startRefresh(isUserInitiated: Bool) {
        print("isRefreshing", isRefreshing)
        guard !isRefreshing else { return }
        
        // decide if refresh should proceed
//        let isStale = (Defaults[.libraryLastRefresh]?.timeIntervalSinceNow ?? -3600) <= -3600
//        guard isUserInitiated || (Defaults[.libraryAutoRefresh] && isStale) else { return }
        
        // start refresh
        LibraryViewModel.operationQueue.progress.totalUnitCount += 1
        LibraryViewModel.operationQueue.addOperation(LibraryRefreshOperation())
    }
    
    // MARK: - Management
    
    /// Configure a zim file object based on its metadata.
    static func configureZimFile(_ zimFile: ZimFile, metadata: ZimFileMetaData) {
        zimFile.articleCount = metadata.articleCount.int64Value
        zimFile.category = metadata.category
        zimFile.created = metadata.creationDate
        zimFile.fileDescription = metadata.fileDescription
        zimFile.fileID = metadata.fileID
        zimFile.flavor = metadata.flavor
        zimFile.hasDetails = metadata.hasDetails
        zimFile.hasPictures = metadata.hasPictures
        zimFile.hasVideos = metadata.hasVideos
        zimFile.languageCode = metadata.languageCode
        zimFile.mediaCount = metadata.mediaCount.int64Value
        zimFile.name = metadata.title
        zimFile.persistentID = metadata.groupIdentifier
        zimFile.requiresServiceWorkers = metadata.requiresServiceWorkers
        zimFile.size = metadata.size.int64Value
        
        // Only overwrite favicon data and url if there is a new value
        if let url = metadata.downloadURL { zimFile.downloadURL = url }
        if let url = metadata.faviconURL { zimFile.faviconURL = url }
    }
    
    /// Open a zim file with file url.
    /// - Parameter url: url of the zim file on disk
    static func open(url: URL) {
        guard let metadata = ZimFileService.getMetaData(url: url),
              let fileURLBookmark = ZimFileService.getBookmarkData(url: url) else { return }
        // open the file
        do {
            try ZimFileService.shared.open(bookmark: fileURLBookmark)
        } catch {
            return
        }
        
        // upsert zim file in the database
        Database.shared.container.performBackgroundTask { context in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            let predicate = NSPredicate(format: "fileID == %@", metadata.fileID as CVarArg)
            let fetchRequest = ZimFile.fetchRequest(predicate: predicate)
            guard let zimFile = try? context.fetch(fetchRequest).first ?? ZimFile(context: context) else { return }
            LibraryViewModel.configureZimFile(zimFile, metadata: metadata)
            zimFile.fileURLBookmark = fileURLBookmark
            zimFile.isMissing = false
            if context.hasChanges { try? context.save() }
        }
    }
    
    
    /// Reopen zim files from url bookmark data.
    static func reopen() {
        let context = Database.shared.container.viewContext
        let request = ZimFile.fetchRequest(predicate: ZimFile.withFileURLBookmarkPredicate)
        guard let zimFiles = try? context.fetch(request) else { return }
        zimFiles.forEach { zimFile in
            guard let data = zimFile.fileURLBookmark else { return }
            do {
                if let data = try ZimFileService.shared.open(bookmark: data) {
                    zimFile.fileURLBookmark = data
                }
                zimFile.isMissing = false
            } catch ZimFileOpenError.missing {
                zimFile.isMissing = true
            } catch {
                zimFile.fileURLBookmark = nil
                zimFile.isMissing = false
            }
        }
        if context.hasChanges {
            try? context.save()
        }
    }
    
    /// Unlink a zim file from library, and delete the file.
    /// - Parameter zimFile: the zim file to delete
    static func delete(zimFileID: UUID) {
        LibraryViewModel.unlink(zimFileID: zimFileID)
    }
    
    /// Unlink a zim file from library, but don't delete the file.
    /// - Parameter zimFile: the zim file to unlink
    static func unlink(zimFileID: UUID) {
        ZimFileService.shared.close(fileID: zimFileID)
        
        Database.shared.container.performBackgroundTask { context in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            guard let zimFile = try? ZimFile.fetchRequest(fileID: zimFileID).execute().first else { return }
            if zimFile.downloadURL == nil {
                context.delete(zimFile)
            } else {
                zimFile.fileURLBookmark = nil
                zimFile.isMissing = false
            }
            if context.hasChanges { try? context.save() }
        }
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
                        LibraryViewModel.configureZimFile(zimFile, metadata: metadata)
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
