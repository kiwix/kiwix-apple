//
//  LibraryRefreshOperation.swift
//  Kiwix
//
//  Created by Chris Li on 10/18/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import RealmSwift
import SwiftyUserDefaults

class LibraryRefreshOperation: Operation, XMLParserDelegate, ZimFileProcessing {
    private(set) var hasUpdates = false // true only when zim files are added or removed, not including updates
    private(set) var error: Error?
    private let updateExisting: Bool
    private var zimFileMetas = [String: [String: Any]]()
    
    init(updateExisting: Bool = false) {
        self.updateExisting = updateExisting
        super.init()
    }
    
    override func main() {
        execute()
    }
    
    func execute() {
        do {
            let data = try fetchData()
            
            // parse response data
            let parser = XMLParser(data: data)
            parser.delegate = self
            parser.parse()
            
            // database
            let database = try Realm(configuration: Realm.defaultConfig)
            try database.write {
                // remove old zimFiles
                let predicate = NSPredicate(format: "NOT id IN %@ AND stateRaw == %@", Set(zimFileMetas.keys), ZimFile.State.cloud.rawValue)
                database.objects(ZimFile.self).filter(predicate).forEach({
                    database.delete($0)
                    self.hasUpdates = true
                })

                // upsert zimFiles
                for (zimFileID, meta) in zimFileMetas {
                    if let zimFile = database.object(ofType: ZimFile.self, forPrimaryKey: zimFileID) {
                        if updateExisting {
                            update(zimFile: zimFile, meta: meta)
                        }
                    } else {
                        let zimFile = create(database: database, id: zimFileID, meta: meta)
                        zimFile.state = .cloud
                        self.hasUpdates = true
                    }
                }
            }

            // apply language filter if library has never been refreshed
            if Defaults[.libraryLastRefreshTime] == nil, let code = Locale.current.languageCode {
                Defaults[.libraryFilterLanguageCodes] = [code]
            }

            // update last library refresh time
            Defaults[.libraryLastRefreshTime] = Date()
            
            print("Library Refresh Procedure finished, has updates: \(hasUpdates)")
        } catch {
        }
    }
    
    private func fetchData() throws -> Data {
        NetworkActivityController.shared.taskDidStart(identifier: "DownloadLibrary")
        defer { NetworkActivityController.shared.taskDidFinish(identifier: "DownloadLibrary") }
        
        var data: Data?
        var error: Swift.Error?
        
        let semaphore = DispatchSemaphore(value: 0)
        let url = URL(string: "https://download.kiwix.org/library/library_zim.xml")!
        let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
        
        URLSession.shared.dataTask(with: request) {
            data = $0
            error = $2
            semaphore.signal()
        }.resume()
        semaphore.wait()
        
        if let data = data {
            return data
        } else {
            throw Error(title: NSLocalizedString("Library Refresh", comment: "Library Refresh Error"),
                        description: error?.localizedDescription ?? NSLocalizedString("Unable to fetch data", comment: "Library Refresh Error"))
        }
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        guard elementName == "book", let zimFileID = attributeDict["id"] else {return}
        zimFileMetas[zimFileID] = attributeDict
    }

    // MARK: -
    
    struct Error: Swift.Error {
        let title: String
        let description: String
        
        init(title: String, description: String) {
            self.title = title
            self.description = description
        }
    }
}
