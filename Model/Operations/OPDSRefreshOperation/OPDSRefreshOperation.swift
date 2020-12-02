//
//  OPDSRefreshOperation.swift
//  Kiwix
//
//  Created by Chris Li on 3/8/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import os
import Defaults
import RealmSwift

class OPDSRefreshOperation: LibraryOperationBase {
    let progress = Progress(totalUnitCount: 10)
    private let updateExisting: Bool

    private(set) var additionCount = 0
    private(set) var updateCount = 0
    private(set) var deletionCount = 0
    private(set) var error: OPDSRefreshError?

    var hasUpdates: Bool {
        return additionCount > 0 || updateCount > 0 || deletionCount > 0
    }

    init(updateExisting: Bool = false) {
        self.updateExisting = updateExisting
        super.init()
    }

    override func main() {
        do {
            os_log("OPDSRefreshOperation started.", log: Log.OPDS, type: .debug)

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

            os_log("OPDSRefreshOperation success -- addition: %d, update: %d, deletion: %d, total: %d",
                   log: Log.OPDS,
                   type: .default,
                   additionCount,
                   updateCount,
                   deletionCount,
                   parser.zimFileIDs.count
            )

        } catch let error as OPDSRefreshError {
            self.error = error
            os_log("OPDSRefreshOperation error: %s", log: Log.OPDS, type: .error, error.localizedDescription)
        } catch {
            os_log("OPDSRefreshOperation unknown error: %s", log: Log.OPDS, type: .error, error.localizedDescription)
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
        progress.addChild(dataTask.progress, withPendingUnitCount: 8)

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
            let zimFileIDs = Set(parser.zimFileIDs)
            let database = try Realm(configuration: Realm.defaultConfig)
            try database.write {
                // remove old zimFiles
                let predicate = NSPredicate(
                    format: "NOT id IN %@ AND stateRaw == %@", zimFileIDs, ZimFile.State.remote.rawValue
                )
                database.objects(ZimFile.self).filter(predicate).forEach({
                    database.delete($0)
                    self.deletionCount += 1
                })

                // upsert new and existing zimFiles
                for zimFileID in zimFileIDs {
                    guard let meta = parser.getZimFileMetaData(id: zimFileID) else { continue }
                    if ZimFile.Category(rawValue: meta.category) == nil { meta.category = ZimFile.Category.other.rawValue }
                    if let zimFile = database.object(ofType: ZimFile.self, forPrimaryKey: zimFileID) {
                        if updateExisting {
                            updateZimFile(zimFile, meta: meta)
                            self.updateCount += 1
                        } else {
                            // HACK: always update groupID, because I forgot to set it on creation before
                            zimFile.groupID = meta.groupIdentifier
                            // HACK: always update category, because I forgot to set unrecognized category to other
                            zimFile.categoryRaw = meta.category
                        }
                    } else {
                        let zimFile = ZimFile()
                        zimFile.id = meta.identifier
                        updateZimFile(zimFile, meta: meta)
                        zimFile.state = .remote
                        database.add(zimFile)
                        self.additionCount += 1
                    }
                }
            }
        } catch {
            throw OPDSRefreshError.process
        }
    }
}
