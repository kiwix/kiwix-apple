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

public class LibraryViewModel: ObservableObject {
    @Published var selectedZimFile: ZimFile?
    @MainActor @Published public private(set) var error: Error?
    @MainActor @Published public private(set) var isInProgress = false
    
    private let urlSession: URLSession
    private let context: NSManagedObjectContext
    private var insertionCount = 0
    private var deletionCount = 0
    
    public init(urlSession: URLSession? = nil) {
        self.urlSession = urlSession ?? URLSession.shared
        
        context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = Database.shared.container.persistentStoreCoordinator
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        context.undoManager = nil
    }
    
    public func start(isUserInitiated: Bool) {
        Task { await start(isUserInitiated: isUserInitiated) }
    }
    
    @MainActor
    public func start(isUserInitiated: Bool) async {
        do {
            guard !isInProgress else { return }
            isInProgress = true
            defer { isInProgress = false }
            
            // decide if refresh should proceed
            let lastRefresh: Date? = Defaults[.libraryLastRefresh]
            let hasAutoRefresh: Bool = Defaults[.libraryAutoRefresh]
            let isStale = (lastRefresh?.timeIntervalSinceNow ?? -3600) <= -3600
            guard isUserInitiated || (hasAutoRefresh && isStale) else { return }

            // refresh library
            guard let data = try await fetchData() else { return }
            let parser = try await parse(data: data)
            try await process(parser: parser)
            
            // update library last refresh timestamp
            Defaults[.libraryLastRefresh] = Date()
            
            // populate library language code if there isn't one set already
            await setDefaultContentFilterLanguage()
            // reset error
            error = nil
            
            // logging
            os_log("Refresh finished -- addition: %d, deletion: %d, total: %d",
                   log: Log.OPDS, type: .default, insertionCount, deletionCount, parser.zimFileIDs.count)
        } catch {
            self.error = error
        }
    }
    
    /// The fetched content is filtered by the languages set in settings.
    /// Try to set it to the device language, making sure we have content to display.
    /// Falls back to English, where most of the content is.
    /// This is only affecting the "fresh-install" defaults.
    /// The user can always set the prefered content languages in settings.
    private func setDefaultContentFilterLanguage() async {
        guard Defaults[.libraryLanguageCodes].isEmpty else {
            return // it was already set earlier (either by default or the user)
        }

        let defaultLangCode: String

        if #available(iOS 16, macOS 13, *) {
            let languages = await Languages.fetch()
            // Double check if the current device language is on the list of languages,
            // and there is content in that language
            if let deviceLang = Locale.current.language.languageCode?.identifier(.alpha3),
               languages.contains(where: { (lang: Language) in
                   lang.code == deviceLang && lang.count > 0
               }) {
                defaultLangCode  = deviceLang
            } else {
                defaultLangCode = "eng"
            }
        } else {
            // Locale.current.languageCode is returning a 2 char lang code, eg: "en"
            // we want a 3 char value, eg: "eng", otherwise we filter out every results
            // and end up with an empty list in the categories
            defaultLangCode = "eng"
        }

        Defaults[.libraryLanguageCodes] = [defaultLangCode]
    }

    private func fetchData() async throws -> Data? {
        guard let url = URL(string: "https://library.kiwix.org/catalog/v2/entries?count=-1") else { return nil }
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
