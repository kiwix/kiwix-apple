//
//  LibraryViewModel.swift
//  Kiwix
//
//  Created by Chris Li on 5/22/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import CoreData

import Defaults

class LibraryViewModel: ObservableObject {
    @Published private(set) var isRefreshing = false
    
    static let backgroundTaskIdentifier = "org.kiwix.library_refresh"
    
    /// Unlink a zim file from library, and delete the file.
    /// - Parameter zimFile: the zim file to delete
    static func delete(zimFileID: UUID) {
        LibraryViewModel.unlink(zimFileID: zimFileID)
    }
    
    /// Unlink a zim file from library, but don't delete the file.
    /// - Parameter zimFile: the zim file to unlink
    static func unlink(zimFileID: UUID) {
        ZimFileService.shared.close(fileID: zimFileID)
        
        let context = Database.shared.container.newBackgroundContext()
        context.perform {
            guard let zimFile = try? ZimFile.fetchRequest(fileID: zimFileID).execute().first else { return }
            if zimFile.downloadURL == nil {
                context.delete(zimFile)
            } else {
                zimFile.fileURLBookmark = nil
            }
            try? context.save()
        }
    }
    
    // MARK: - Language
    
    /// Retrieve a list of languages.
    /// - Returns: languages with count of zim files in each language
    func fetchLanguages() async -> [Language] {
        let count = NSExpressionDescription()
        count.name = "count"
        count.expression = NSExpression(forFunction: "count:", arguments: [NSExpression(forKeyPath: "languageCode")])
        count.expressionResultType = .integer16AttributeType
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ZimFile")
        fetchRequest.propertiesToFetch = ["languageCode", count]
        fetchRequest.propertiesToGroupBy = ["languageCode"]
        fetchRequest.resultType = .dictionaryResultType
        
        let languages: [Language] = await withCheckedContinuation { continuation in
            let context = Database.shared.container.newBackgroundContext()
            context.perform {
                guard let results = try? context.fetch(fetchRequest) else {
                    continuation.resume(returning: [])
                    return
                }
                let language: [Language] = results.compactMap { result in
                    guard let result = result as? NSDictionary,
                          let languageCode = result["languageCode"] as? String,
                          let count = result["count"] as? Int else { return nil }
                    return Language(code: languageCode, count: count)
                }
                continuation.resume(returning: language)
            }
        }
        return languages
    }
    
    /// Compare two languages based on library language sorting order.
    /// Can be removed once support for iOS 14 drops.
    /// - Parameters:
    ///   - lhs: one language to compare
    ///   - rhs: another language to compare
    /// - Returns: if one language should appear before or after another
    static func compareLanguage(lhs: Language, rhs: Language) -> Bool {
        switch Defaults[.libraryLanguageSortingMode] {
        case .alphabetically:
            return lhs.name.caseInsensitiveCompare(rhs.name) == .orderedAscending
        case .byCounts:
            return lhs.count > rhs.count
        }
    }
    
    // MARK: - Refresh
    
    /// Batch update the local zim file database with what's available online.
    func refresh(isUserInitiated: Bool) async throws {
        DispatchQueue.main.async { self.isRefreshing = true }
        defer { DispatchQueue.main.async { self.isRefreshing = false } }
        
        // decide if update should proceed
        guard isUserInitiated ||
            (Defaults[.libraryAutoRefresh] && (Defaults[.libraryLastRefresh]?.timeIntervalSinceNow ?? -3600) <= -3600)
        else { return }
        
        // download data
        guard let url = URL(string: "https://library.kiwix.org/catalog/root.xml") else { return }
        let data: Data = try await withCheckedThrowingContinuation { continuation in
            URLSession.shared.dataTask(with: url) { data, response, error in
                guard let response = response as? HTTPURLResponse, response.statusCode == 200, let data = data else {
                    let error = OPDSRefreshError.retrieve(description: "Error retrieving online catalog.")
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: data)
            }.resume()
        }
        
        // parse data
        try Task.checkCancellation()
        let parser: OPDSStreamParser = try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global().async {
                do {
                    let parser = OPDSStreamParser()
                    try parser.parse(data: data)
                    continuation.resume(returning: parser)
                } catch {
                    continuation.resume(throwing: OPDSRefreshError.process)
                }
            }
        }
        
        // create context
        let context = Database.shared.container.newBackgroundContext()
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        context.undoManager = nil
        
        // process data
        try Task.checkCancellation()
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) -> Void in
            context.perform {
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
                                self.configureZimFile(zimFile, metadata: metadata)
                                return false
                            }
                            return true
                        }
                    )
                    insertRequest.resultType = .count
                    let insertResult = try context.execute(insertRequest) as? NSBatchInsertResult
                    print("Added \(insertResult?.result ?? 0) zim files entities.")
                    
                    // delete old zim files
                    let fetchRequest: NSFetchRequest<NSFetchRequestResult> = ZimFile.fetchRequest()
                    fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                        NSPredicate(format: "fileURLBookmark == nil"),
                        NSPredicate(format: "NOT fileID IN %@", parser.zimFileIDs.compactMap { UUID(uuidString: $0) })
                    ])
                    let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                    deleteRequest.resultType = .resultTypeCount
                    let deleteResult = try context.execute(deleteRequest) as? NSBatchDeleteResult
                    print("Deleted \(deleteResult?.result ?? 0) zim files entities.")
                } catch {
                    continuation.resume(throwing: OPDSRefreshError.process)
                }
                continuation.resume()
            }
        }
        
        // Update user defaults
        Defaults[.libraryLastRefresh] = Date()
        if Defaults[.libraryLanguageCodes].isEmpty, let currentLanguageCode = Locale.current.languageCode {
            Defaults[.libraryLanguageCodes] = [currentLanguageCode]
        }
    }
    
    /// Configure a zim file object based on its metadata.
    private func configureZimFile(_ zimFile: ZimFile, metadata: ZimFileMetaData) {
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
        zimFile.size = metadata.size.int64Value
        
        // Only overwrite favicon data and url if there is a new value
        if let url = metadata.downloadURL { zimFile.downloadURL = url }
        if let url = metadata.faviconURL { zimFile.faviconURL = url }
    }
    
    static let dateFormatterShort: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let dateFormatterMedium: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let sizeFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()
    
    static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    static let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        return formatter
    }()
    
    static func formattedLargeNumber(from value: Int64) -> String {
        let sign = ((value < 0) ? "-" : "" )
        let abs = Swift.abs(value)
        guard abs >= 1000 else {return "\(sign)\(abs)"}
        let exp = Int(log10(Double(abs)) / log10(1000))
        let units = ["K", "M", "G", "T", "P", "E"]
        let rounded = round(10 * Double(abs) / pow(1000.0,Double(exp))) / 10;
        return "\(sign)\(rounded)\(units[exp-1])"
    }
}
