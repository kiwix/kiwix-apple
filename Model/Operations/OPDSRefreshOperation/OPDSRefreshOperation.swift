//
//  OPDSRefreshOperation.swift
//  Kiwix
//
//  Created by Chris Li on 3/8/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import CoreData
import os
import Defaults
import RealmSwift

class OPDSRefreshOperation: LibraryOperationBase {
    private let updateExisting: Bool

    private(set) var additionCount = 0
    private(set) var updateCount = 0
    private(set) var deletionCount = 0
    private(set) var error: OPDSRefreshError?

    var hasUpdates: Bool {
        additionCount > 0 || updateCount > 0 || deletionCount > 0
    }

    init(updateExisting: Bool = false) {
        self.updateExisting = updateExisting
        super.init()
    }

    override func main() {
        do {
            os_log("Refresh started.", log: Log.OPDS, type: .debug)

            // refresh the library
            let data = try fetchData()
            let parser = OPDSStreamParser()
            try parser.parse(data: data)
            try processData(parser: parser)

            DispatchQueue.main.sync {
                // apply language filter if library has never been refreshed
                if Defaults[.libraryLastRefreshTime] == nil, let code = Locale.current.languageCode {
                    Defaults[.libraryFilterLanguageCodes] = [code]
                }

                // update last library refresh time
                Defaults[.libraryLastRefreshTime] = Date()
            }

            os_log("Refresh succeed -- addition: %d, update: %d, deletion: %d, total: %d",
                   log: Log.OPDS,
                   type: .default,
                   additionCount,
                   updateCount,
                   deletionCount,
                   parser.zimFileIDs.count
            )
        } catch let error as OPDSRefreshError {
            self.error = error
            os_log("Refresh error: %s", log: Log.OPDS, type: .error, error.localizedDescription)
        } catch {
            os_log("Refresh unknown error: %s", log: Log.OPDS, type: .error, error.localizedDescription)
        }
    }

    /// Retrieve the whole OPDS stream from library.kiwix.org
    /// - Throws: OPDSRefreshError, the error happened during OPDS stream retrieval
    /// - Returns: Data, a data object containing the OPDS stream
    private func fetchData() throws -> Data {
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
            os_log("Retrieved OPDS Stream, length: %llu", log: Log.OPDS, type: .info, data.count)
            return data
        } else {
            let description = error?.localizedDescription ??
                NSLocalizedString("Unable to fetch data", comment: "Library Refresh Error")
            os_log("Retrieving OPDS Stream error: %s", log: Log.OPDS, type: .error, description)
            throw OPDSRefreshError.retrieve(description: description)
        }
    }

    /// Process the parsed OPDS stream
    /// - Parameter parser: OPDSStreamParser
    /// - Throws: OPDSRefreshError, the error happened during OPDS stream processing
    private func processData(parser: OPDSStreamParser) throws {
        do {
            // get zim file metadata
            // skip ones that require service worker to function
            let metadata = parser.zimFileIDs.compactMap { parser.getZimFileMetaData(id: $0) }
                .filter { !$0.requiresServiceWorker }
            
            // calculate the number of additions
            let database = try Realm(configuration: Realm.defaultConfig)
            let existing = database.objects(ZimFile.self)
                .filter(NSPredicate(format: "fileID IN %@", Set(metadata.map({ $0.identifier }))))
            self.additionCount = metadata.count - existing.count
            
            // update the database
            try database.write {
                // upsert new zim files
                for item in metadata {
                    database.create(ZimFile.self, value: [
                        "fileID": item.identifier,
                        "groupId": item.groupIdentifier,
                        "title": item.title,
                        "fileDescription": item.fileDescription,
                        "languageCode": item.languageCode,
                        "categoryRaw": (ZimFile.Category(rawValue: item.category) ?? .other).rawValue,
                        "creator": item.creator,
                        "publisher": item.publisher,
                        "creationDate": item.creationDate,
                        "downloadURL": item.downloadURL?.absoluteString as Any,
                        "faviconURL": item.faviconURL?.absoluteString as Any,
                        "size": item.size.int64Value,
                        "articleCount": item.articleCount.int64Value,
                        "mediaCount": item.mediaCount.int64Value,
                        "hasDetails": item.hasDetails,
                        "hasPictures": item.hasPictures,
                        "hasVideos": item.hasVideos,
                    ], update: .modified)
                }
                
                // delete outdated zim files (that are not on device or being downloaded)
                let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                    NSPredicate(format: "stateRaw = %@", ZimFile.State.remote.rawValue),
                    NSPredicate(format: "NOT fileID IN %@", Set(metadata.map({ $0.identifier }))),
                ])
                let outdated = database.objects(ZimFile.self).filter(predicate)
                self.deletionCount = outdated.count
                database.delete(outdated)
            }
        } catch {
            throw OPDSRefreshError.process
        }
    }
}
