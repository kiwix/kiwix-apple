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
import os

enum LibraryState {
    case initial
    case inProgress
    case complete
    case error

    static func defaultState(defaults: Defaulting = UDefaults()) -> LibraryState {
        if defaults[.libraryLastRefresh] == nil {
            return .initial
        } else {
            return .complete
        }
    }
}

/// Makes sure that the process value is stored in a single state
/// regardless of the amount of instances we have for LibraryViewModel
@MainActor final class LibraryProcess: ObservableObject {
    static let shared = LibraryProcess()
    @Published var state: LibraryState

    init(defaultState: LibraryState = .defaultState()) {
        state = defaultState
    }
}

// MARK: LibraryViewModel

@MainActor
final class LibraryViewModel: ObservableObject {
    private struct SyncCount {
        var inserted: UInt = 0
        var deleted: UInt = 0
        var updated: UInt = 0
    }
    
    @Published private(set) var error: Error?
    /// Note: due to multiple instances of LibraryViewModel,
    /// this `state` should not be changed directly, modify the `process.state` instead
    @Published var state: LibraryState
    private let process: LibraryProcess
    private var cancellables = Set<AnyCancellable>()
    private let defaults: Defaulting
    private let categories: CategoriesProtocol

    private let urlSession: URLSession
    private var syncCount = SyncCount()
    
    private static let catalogURL = URL(string: "https://opds.library.kiwix.org/catalog/v2/entries?count=-1")!

    init(
        urlSession: URLSession = URLSession.shared,
        processFactory: @MainActor () -> LibraryProcess = { .shared },
        defaults: Defaulting = UDefaults(),
        categories: CategoriesProtocol = CategoriesToLanguages(withDefaults: UDefaults()),
    ) {
        self.urlSession = urlSession
        self.process = processFactory()
        self.defaults = defaults
        self.categories = categories
        state = process.state
        process.$state.sink { [weak self] newState in
            self?.state = newState
        }.store(in: &cancellables)
    }

    func start(isUserInitiated: Bool) async {
        guard process.state != .inProgress else { return }
        do {
            // decide if refresh should proceed
            let lastRefresh: Date? = defaults[.libraryLastRefresh]
            let hasAutoRefresh: Bool = defaults[.libraryAutoRefresh]
            let isStale = (lastRefresh?.timeIntervalSinceNow ?? -3600) <= -3600
            guard isUserInitiated || (hasAutoRefresh && isStale) else { return }

            process.state = .inProgress

            // refresh library
            guard case (let data, let responseURL)? = try await fetchData() else {
                // this is the case when we have no new data (304 http)
                // but we still need to refresh the memory only stored
                // zimfile categories to languages dictionary
                if categories.allCategories().count < 2 {
                    let context = Database.shared.viewContext
                    let zimFiles: [ZimFile]? = try? await context.perform {
                        try ZimFile.fetchRequest().execute()
                    }
                    if let zimFiles {
                        saveCategoryAvailableInLanguages(fromDBZimFiles: zimFiles)
                        // populate library language code if there isn't one set already
                        await setDefaultContentFilterLanguage()
                        
                        error = nil
                        process.state = .complete
                        return
                    } else {
                        error = LibraryRefreshError.process
                        process.state = .error
                        return
                    }
                } else {
                    error = nil
                    process.state = .complete
                    return
                }
            }
            let parsed = try await parse(data: data, urlHost: responseURL)
            // process the feed
            try await process(parsed: parsed)

            // update library last refresh timestamp
            defaults[.libraryLastRefresh] = Date()

            saveCategoryAvailableInLanguages(using: parsed)

            // populate library language code if there isn't one set already
            await setDefaultContentFilterLanguage()

            // reset error
            error = nil
            process.state = .complete

            // logging
            let totalCount = parsed.results.count
            Log.OPDS.notice("""
Refresh finished -- insertion: \(self.syncCount.inserted, privacy: .public), \
deletion: \(self.syncCount.deleted, privacy: .public), \
update: \(self.syncCount.updated, privacy: .public), \
total: \(totalCount, privacy: .public)
""")
        } catch {
            self.error = error
            process.state = .error
        }
    }

    private func saveCategoryAvailableInLanguages(using parsedData: Parsed) {
        var dictionary: [Category: Set<String>] = [:]
        for (key: _, value: meta) in parsedData.results {
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
        categories.save(dictionary)
    }
    
    private func saveCategoryAvailableInLanguages(fromDBZimFiles zimFiles: [ZimFile]) {
        var dictionary: [Category: Set<String>] = [:]
        for zimFile in zimFiles {
            let category = Category(rawValue: zimFile.category) ?? .other
            let allLanguagesForCategory: Set<String>
            let categoryLanguages: Set<String> = Set<String>(zimFile.languageCode.components(separatedBy: ","))
            if let existingLanguages = dictionary[category] {
                allLanguagesForCategory = existingLanguages.union(categoryLanguages)
            } else {
                allLanguagesForCategory = categoryLanguages
            }
            dictionary[category] = allLanguagesForCategory
        }
        categories.save(dictionary)
    }

    /// The fetched content is filtered by the languages set in settings.
    /// We need to make sure, whatever was set by the user is
    /// still on the list of languages we now have from the feed
    private func setDefaultContentFilterLanguage() async {
        let languages = await Languages.fetch()
        let validCodes = Set<String>(languages.map { $0.code })
        // preserve only valid selections by:
        // converting earlier user selections, and filtering out invalid ones
        let validForUser = LanguagesConverter.convert(codes: Set(defaults[.libraryLanguageCodes]),
                                                        validCodes: validCodes)
        // save it back to user defaults, but preserve the ordering
        defaults[.libraryLanguageCodes] = defaults[.libraryLanguageCodes].filter { code in
            validForUser.contains(code)
        }

        guard defaults[.libraryLanguageCodes].isEmpty else {
            // what was earlier set by the user or picked by default is valid
            return
        }
        // since the user defaults are empty,
        // from this point below, the original ordering doesn't matter anymore

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
            defaults[.libraryLanguageCodes] = [fallbackToEnglish]
        } else {
            defaults[.libraryLanguageCodes] = validDefaults.sorted() // sorted, but just to make it an array
        }
    }

    private func fetchData() async throws -> (Data, URL)? {
        do {
            var request = URLRequest(url: Self.catalogURL, timeoutInterval: 20)
            request.allHTTPHeaderFields = ["If-None-Match": defaults[.libraryETag]]
            let (data, response) = try await self.urlSession.data(for: request)
            guard let response = response as? HTTPURLResponse else { return nil }
            switch response.statusCode {
            case 200:
                let responseURL = response.url ?? Self.catalogURL
                if let eTag = response.allHeaderFields["Etag"] as? String {
                    defaults[.libraryETag] = eTag
                }
                // OK to process further
                Log.OPDS.debug("Retrieved OPDS Data, size: \(data.count, format: .byteCount, privacy: .public) bytes")
                return (data, responseURL)
            case 304:
                return nil // already downloaded
            default:
                throw LibraryRefreshError.retrieve(description: "HTTP Status \(response.statusCode).")
            }
        } catch {
            Log.OPDS.error("Error retrieving OPDS Data: \(error.localizedDescription, privacy: .public)")
            if let error = error as? LibraryRefreshError {
                throw error
            } else {
                throw LibraryRefreshError.retrieve(description: error.localizedDescription)
            }
        }
    }

    @ParserActor
    private func parse(data: Data, urlHost: URL) async throws -> Parsed {
        let parser = OPDSParser()
        let urlHostString = urlHost
            .withoutQueryParams()
            .trim(pathComponents: ["catalog", "v2", "entries"])
            .absoluteString
        try await parser.parse(data: data, urlHost: urlHostString)
        return await parser.results()
    }

    // swiftlint:disable:next function_body_length
    private func process(parsed: Parsed) async throws {
        // Sync the local DB entries with the parsed feed:
        // 1) delete everything from the DB, that has no downloaded file already
        // 2) insert new entries from the feed: we had no record of those yet in the DB
        // 3) for already downloaded entries, only update their download URL
        // their metadata and other local values should not be touched
        // In case of deleting and re-downloading them we want to have the right URL.
        // Otherwise if those are removed locally (no longer downloaded), the next sync will update them in full
        let downloadedIds: [UUID] = await Database.shared.viewContext.perform {
            if let zimFiles = try? ZimFile.fetchRequest(predicate: ZimFile.Predicate.isDownloaded()).execute() {
                return zimFiles.map { $0.fileID }
            } else {
                return []
            }
        }
        let parsedIds: Set<UUID> = Set(parsed.results.keys)
        let insertIds: Set<UUID> = parsedIds.subtracting(downloadedIds)
        let downloadURLUpdates: [UUID: URL?] = downloadedIds.reduce(into: [:]) { partialResult, uuid in
            partialResult[uuid] = parsed.results[uuid]?.downloadURL
        }
    
        do {
            // delete everything from the DB, that has no downloaded file already
            let deleteCount: Int = try await Database.shared.viewContext.perform(schedule: .enqueued) {
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = ZimFile.fetchRequest()
                fetchRequest.predicate = ZimFile.Predicate.notDownloaded()
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                deleteRequest.resultType = .resultTypeCount
                let context = Database.shared.viewContext
                if let result = try context.execute(deleteRequest) as? NSBatchDeleteResult {
                    return result.result as? Int ?? 0
                }
                return 0
            }
            
            // insert new entries from the feed
            let insertCount: Int = try await Database.shared.viewContext.perform(schedule: .enqueued) {
                var zimFileIDs = insertIds
                let insertRequest = NSBatchInsertRequest(
                    entity: ZimFile.entity(),
                    managedObjectHandler: { zimFile in
                        guard let zimFile = zimFile as? ZimFile else { return true }
                        while !zimFileIDs.isEmpty {
                            guard let id = zimFileIDs.popFirst(),
                                  let metadata = parsed.results[id] else { continue }
                            LibraryOperations.configureZimFile(zimFile, metadata: metadata)
                            return false
                        }
                        return true
                    }
                )
                insertRequest.resultType = .count
                let context = Database.shared.viewContext
                if let result = try context.execute(insertRequest) as? NSBatchInsertResult {
                    return result.result as? Int ?? 0
                } else {
                    return 0
                }
            }
            
            // for the download entries, only update their download URL
            let updateCount: Int = await Database.shared.viewContext.perform(schedule: .enqueued) {
                let context = Database.shared.viewContext
                var count: Int = 0
                for (fileID, url) in downloadURLUpdates {
                    guard let url else { continue } // don't update with a nil url value
                    let request = NSBatchUpdateRequest(
                        entity: ZimFile.entity(),
                    )
                    request.predicate = NSPredicate(format: "fileID == %@", fileID as CVarArg)
                    request.propertiesToUpdate = ["downloadURL": url as CVarArg]
                    request.includesSubentities = false
                    request.resultType = .updatedObjectsCountResultType
                    if let result = try? context.execute(request) as? NSBatchUpdateResult {
                        assert(result.result as? Int == 1)
                        count += 1
                    }
                }
                return count
            }
            
            syncCount.inserted = UInt(insertCount)
            syncCount.deleted = UInt(deleteCount)
            syncCount.updated = UInt(updateCount)
        } catch {
            Log.OPDS.error("Error saving OPDS Data: \(error.localizedDescription, privacy: .public)")
            throw LibraryRefreshError.process
        }
    }
}
