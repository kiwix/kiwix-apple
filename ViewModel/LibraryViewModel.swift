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

import CoreData
import Combine
import Defaults
import os

enum LibraryState {
    case initial
    case inProgress
    case complete
}

/// Makes sure that the process value is stored in a single state
/// regardless of the amount of instances we have for LibraryViewModel
@MainActor final class LibraryProcess: ObservableObject {
    static let shared = LibraryProcess()
    @Published var state: LibraryState

    private init() {
        if Defaults[.libraryLastRefresh] == nil {
            state = .initial
        } else {
            state = .complete
        }
    }
}


final class LibraryViewModel: ObservableObject {
    @Published var selectedZimFile: ZimFile?
    @MainActor @Published private(set) var error: Error?
    /// Note: due to multiple instances of LibraryViewModel,
    /// this `state` should not be changed directly, modify the `process.state` instead
    @MainActor @Published var state: LibraryState
    @MainActor private let process: LibraryProcess
    private var cancellables = Set<AnyCancellable>()

    private let urlSession: URLSession
    private let context: NSManagedObjectContext
    private var insertionCount = 0
    private var deletionCount = 0

    @MainActor
    init(urlSession: URLSession? = nil) {
        self.urlSession = urlSession ?? URLSession.shared

        context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = Database.shared.container.persistentStoreCoordinator
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        context.undoManager = nil
        process = LibraryProcess.shared
        state = process.state
        process.$state.sink { [weak self] newState in
            self?.state = newState
        }.store(in: &cancellables)
    }

    func start(isUserInitiated: Bool) {
        Task { await start(isUserInitiated: isUserInitiated) }
    }

    @MainActor
    func start(isUserInitiated: Bool) async {
        guard process.state != .inProgress else { return }
        let oldState = process.state
        do {
            // decide if refresh should proceed
            let lastRefresh: Date? = Defaults[.libraryLastRefresh]
            let hasAutoRefresh: Bool = Defaults[.libraryAutoRefresh]
            let isStale = (lastRefresh?.timeIntervalSinceNow ?? -3600) <= -3600
            guard isUserInitiated || (hasAutoRefresh && isStale) else { return }

            process.state = .inProgress

            // refresh library
            guard let data = try await fetchData() else {
                process.state = oldState
                return
            }
            let parser = try await parse(data: data)
            // delete all old ISO Lang Code entries if needed, by passing in an empty parser
            if Defaults[.libraryUsingOldISOLangCodes] {
                try await process(parser: DeletingParser())
                Defaults[.libraryUsingOldISOLangCodes] = false
            }
            // process the feed
            try await process(parser: parser)

            // update library last refresh timestamp
            Defaults[.libraryLastRefresh] = Date()

            saveCategoryAvailableInLanguages(using: parser)

            // populate library language code if there isn't one set already
            await setDefaultContentFilterLanguage()

            // reset error
            error = nil
            process.state = .complete

            // logging
            os_log("Refresh finished -- addition: %d, deletion: %d, total: %d",
                   log: Log.OPDS, type: .default, insertionCount, deletionCount, parser.zimFileIDs.count)
        } catch {
            self.error = error
            process.state = oldState
        }
    }

    private func saveCategoryAvailableInLanguages(using parser: OPDSParser) {
        var dictionary: [Category: Set<String>] = [:]
        for zimFileID in parser.zimFileIDs {
            if let meta = parser.getMetaData(id: zimFileID) {
                let category = Category(rawValue: meta.category) ?? .other
                let allLanguagesForCategory: Set<String>
                let categoryLanguages: Set<String> = Set<String>(meta.languageCodes.components(separatedBy: ","))
                if let existingLanguages = dictionary[category] {
                    allLanguagesForCategory = existingLanguages.union(categoryLanguages)
                } else {
                    allLanguagesForCategory = categoryLanguages
                }
                dictionary[category] = allLanguagesForCategory
            }
        }
        CategoriesToLanguages.save(dictionary)
    }

    /// The fetched content is filtered by the languages set in settings.
    /// We need to make sure, whatever was set by the user is
    /// still on the list of languages we now have from the feed
    private func setDefaultContentFilterLanguage() async {
        let languages = await Languages.fetch()
        let validCodes = Set<String>(languages.map { $0.code })
        // preserve only valid selections by:
        // converting earlier user selections, and filtering out invalid ones
        Defaults[.libraryLanguageCodes] = LanguagesConverter.convert(codes: Defaults[.libraryLanguageCodes],
                                                                     validCodes: validCodes)

        guard Defaults[.libraryLanguageCodes].isEmpty else {
            return // what was earlier set by the user or picked by default is valid
        }

        // Nothing was set earlier, or validation filtered it out to empty
        // Try to set it to the device language,
        // at the same time make sure, we have content to display, meaning:
        // the device language is on the list of languages from the feed
        // If all that fails: fallback to English, where most of the content is
        let fallbackToEnglish = "eng"
        let deviceLang = Locale.current.language.languageCode?.identifier(.alpha3)
        // convert it to a set, so we can use the same validation function
        let deviceLangSet = Set<String>([deviceLang].compactMap { $0 })
        let validDefaults = LanguagesConverter.convert(codes: deviceLangSet, validCodes: validCodes)
        if validDefaults.isEmpty { // meaning the device language isn't valid (or nil)
            Defaults[.libraryLanguageCodes] = [fallbackToEnglish]
        } else {
            Defaults[.libraryLanguageCodes] = validDefaults
        }
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
            let parser = OPDSParser()
            do {
                try parser.parse(data: data)
                continuation.resume(returning: parser)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func process(parser: Parser) async throws {
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

                    // delete old zim entries not included in the feed
                    let fetchRequest: NSFetchRequest<NSFetchRequestResult> = ZimFile.fetchRequest()
                    fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                        ZimFile.Predicate.notDownloaded,
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
