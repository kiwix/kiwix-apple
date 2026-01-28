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

private struct Count {
    let insertion: Int
    let deletion: Int
    
    func add(_ other: Count) -> Count {
        Count(
            insertion: insertion + other.insertion,
            deletion: deletion + other.deletion
        )
    }
}

// MARK: database protocols
protocol Databasing {
    
    /// For testing purposes only
    func fetchZimFiles() async throws -> [ZimFileStruct]
    func fetchZimFileIds() async throws -> [UUID]
    func fetchZimFileCategoryLanguageData() async throws -> [ZimFileCategoryLanguageData]
    func bulkInsert(metadata: [ZimFileMetaStruct]) async throws -> Int
    func bulkDeleteNotDownloadedZims(notIncludedIn: Set<UUID>) async throws -> Int
}

struct ProductionDatabase: Databasing {
    
    // for testing only atm
    func fetchZimFiles() async throws -> [ZimFileStruct] {
        let zimFiles = try await Database.shared.backgroundContext.perform {
            try ZimFile.fetchRequest().execute()
        }
        return zimFiles.map { zimFile in
            ZimFileStruct(articleCount: zimFile.articleCount,
                          category: zimFile.category,
                          created: zimFile.created,
                          downloadURL: zimFile.downloadURL,
                          faviconData: zimFile.faviconData,
                          faviconURL: zimFile.faviconURL,
                          fileDescription: zimFile.fileDescription,
                          fileID: zimFile.fileID,
                          fileURLBookmark: zimFile.fileURLBookmark,
                          flavor: zimFile.flavor,
                          hasDetails: zimFile.hasDetails,
                          hasPictures: zimFile.hasPictures,
                          hasVideos: zimFile.hasVideos,
                          includedInSearch: zimFile.includedInSearch,
                          isMissing: zimFile.isMissing,
                          languageCode: zimFile.languageCode,
                          mediaCount: zimFile.mediaCount,
                          name: zimFile.name,
                          persistentID: zimFile.persistentID,
                          requiresServiceWorkers: zimFile.requiresServiceWorkers,
                          size: zimFile.size)
        }
    }
    
    func fetchZimFileIds() async throws -> [UUID] {
        try await Database.shared.backgroundContext.perform {
            let request = ZimFile.fetchRequest()
            request.propertiesToFetch = ["fileID"]
            return try request.execute().map { $0.fileID }
        }
    }
    
    func fetchZimFileCategoryLanguageData() async throws -> [ZimFileCategoryLanguageData] {
        try await Database.shared.backgroundContext.perform {
            let request = ZimFile.fetchRequest()
            request.propertiesToFetch = ["category", "languageCode"]
            return try request.execute().map {
                ZimFileCategoryLanguageData(category: $0.category, languageCode: $0.languageCode)
            }
        }
    }
    
    func bulkInsert(metadata: [ZimFileMetaStruct]) async throws -> Int {
        var listOfData = metadata
        let context = Database.shared.backgroundContext
        return await context.perform {
            let insertRequest = NSBatchInsertRequest(
                entity: ZimFile.entity(),
                managedObjectHandler: { zimFile in
                    guard var zimFile = zimFile as? ZimFile else { return true }
                    while let data = listOfData.popLast() {
                        LibraryOperations.configureZimFile(&zimFile, metadata: data)
                        return false
                    }
                    return true
                }
            )
            insertRequest.resultType = .count
            
            guard let result = try? context.execute(insertRequest),
                  let batchResult = result as? NSBatchInsertResult,
                  let insertCount = batchResult.result as? Int
            else {
                return 0
            }
            return insertCount
        }
    }
    
    func bulkDeleteNotDownloadedZims(notIncludedIn: Set<UUID>) async throws -> Int {
        let context = Database.shared.backgroundContext
        return try await context.perform {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = ZimFile.fetchRequest()
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                ZimFile.Predicate.notDownloaded,
                NSPredicate(format: "NOT fileID IN %@", notIncludedIn)
            ])
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            deleteRequest.resultType = .resultTypeCount
            
            if let result = try context.execute(deleteRequest) as? NSBatchDeleteResult {
                return result.result as? Int ?? 0
            }
            return 0
        }
    }
}

// non-isolated ZimFileData
struct ZimFileCategoryLanguageData {
    let category: String
    let languageCode: String
}

// MARK: LibraryViewModel

final class LibraryViewModel: ObservableObject {
    @MainActor @Published private(set) var error: Error?
    /// Note: due to multiple instances of LibraryViewModel,
    /// this `state` should not be changed directly, modify the `process.state` instead
    @MainActor @Published var state: LibraryState
    @MainActor private let process: LibraryProcess
    private var cancellables = Set<AnyCancellable>()
    private let defaults: Defaulting
    private let categories: CategoriesProtocol
    private let database: Databasing
    private let urlSession: URLSession
    
    private static let catalogURL = URL(string: "https://opds.library.kiwix.org/v2/entries?count=-1")!

    @MainActor
    init(
        urlSession: URLSession = URLSession.shared,
        processFactory: @MainActor () -> LibraryProcess = { .shared },
        defaults: Defaulting = UDefaults(),
        categories: CategoriesProtocol = CategoriesToLanguages(withDefaults: UDefaults()),
        database: Databasing = ProductionDatabase()
    ) {
        self.urlSession = urlSession
        self.process = processFactory()
        self.defaults = defaults
        self.categories = categories
        self.database = database
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
                    if let categoryLangData = try? await database.fetchZimFileCategoryLanguageData() {
                        saveCategoryAvailableInLanguages(fromDBZimFiles: categoryLangData)
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
            let parser = try await parse(data: data, urlHost: responseURL)
            var processCount = Count(insertion: 0, deletion: 0)
            // delete all old ISO Lang Code entries if needed, by passing in an empty parser
            if defaults[.libraryUsingOldISOLangCodes] {
                let deleteCount = try await process(parser: DeletingParser())
                processCount = processCount.add(deleteCount)
                defaults[.libraryUsingOldISOLangCodes] = false
            }
            // process the feed
            let feedCount = try await process(parser: parser)
            processCount = processCount.add(feedCount)

            // update library last refresh timestamp
            defaults[.libraryLastRefresh] = Date()

            await saveCategoryAvailableInLanguages(using: parser)

            // populate library language code if there isn't one set already
            await setDefaultContentFilterLanguage()

            // reset error
            error = nil
            process.state = .complete

            // logging
            let totalCount = await parser.zimFileIDs.count
            Log.OPDS.notice("""
Refresh finished -- insertion: \(processCount.insertion, privacy: .public), \
deletion: \(processCount.deletion, privacy: .public), \
total: \(totalCount, privacy: .public)
""")
        } catch {
            self.error = error
            process.state = .error
        }
    }

    private func saveCategoryAvailableInLanguages(using parser: OPDSParser) async {
        var dictionary: [Category: Set<String>] = [:]
        for zimFileID in await parser.zimFileIDs {
            if let meta = await parser.getMetaData(id: zimFileID, fetchFavicon: false) {
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
        categories.save(dictionary)
    }
    
    @MainActor private func saveCategoryAvailableInLanguages(fromDBZimFiles zimFiles: [ZimFileCategoryLanguageData]) {
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
        defaults[.libraryLanguageCodes] = LanguagesConverter.convert(codes: defaults[.libraryLanguageCodes],
                                                                     validCodes: validCodes)

        guard defaults[.libraryLanguageCodes].isEmpty else {
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
            defaults[.libraryLanguageCodes] = [fallbackToEnglish]
        } else {
            defaults[.libraryLanguageCodes] = validDefaults
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

    private func parse(data: Data, urlHost: URL) async throws -> OPDSParser {
        let parser = OPDSParser()
        let urlHostString = urlHost
            .withoutQueryParams()
            .trim(pathComponents: ["catalog", "v2", "entries"])
            .absoluteString
        try await parser.parse(data: data, urlHost: urlHostString)
        return parser
    }
    
    @ZimActor
    private func process(parser: Parser) async throws -> Count {
        let parsedZimFileIDs = parser.zimFileIDs
        do {
            // insert new zim files
            let existingIDs = try await database.fetchZimFileIds()
            let zimFileIDs = parsedZimFileIDs.subtracting(existingIDs)
            let allZimMetaData: [ZimFileMetaStruct] = zimFileIDs.compactMap { uuid in
                // for parsing the whole catalog
                // we don't want to auto-fetch the favicons
                // It takes forever !
                parser.getMetaData(id: uuid, fetchFavicon: false)
            }
            let insertCount = try await database.bulkInsert(metadata: allZimMetaData)
            // delete old zim entries not included in the feed
            let deleteCount = try await database.bulkDeleteNotDownloadedZims(notIncludedIn: parsedZimFileIDs)
            return Count(insertion: insertCount, deletion: deleteCount)
        } catch {
            Log.OPDS.error("Error saving OPDS Data: \(error.localizedDescription, privacy: .public)")
            throw LibraryRefreshError.process
        }
    }
}
