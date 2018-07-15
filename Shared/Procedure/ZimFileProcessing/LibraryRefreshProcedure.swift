//
//  LibraryRefreshProcedure.swift
//  Kiwix
//
//  Created by Chris Li on 10/18/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import RealmSwift
import ProcedureKit
import SwiftyUserDefaults

class LibraryRefreshProcedure: GroupProcedure {
    init(updateExistingZimFiles: Bool = true) {
        let download = DownloadProcedure()
        let process = ProcessProcedure(updateExistingZimFiles: updateExistingZimFiles)
        process.injectResult(from: download)
        super.init(operations: [download, process])
    }
}

private class DownloadProcedure: NetworkDataProcedure<URLSession> {
    init() {
        let session = URLSession.shared
        let url = URL(string: "https://download.kiwix.org/library/library_zim.xml")!
        let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
        super.init(session: session, request: request)
        
        addWillExecuteBlockObserver { _, _ in
            NetworkActivityController.shared.taskDidStart(identifier: "DownloadLibrary")
        }
        
        addDidFinishBlockObserver { _, errors in
            errors.forEach({ print($0) })
            NetworkActivityController.shared.taskDidFinish(identifier: "DownloadLibrary")
        }
    }
}

private class ProcessProcedure: ZimFileProcessingProcedure, InputProcedure, XMLParserDelegate {
    var input: Pending<HTTPPayloadResponse<Data>> = .pending
    private var latest = [String: [String: Any]]()
    private let updateExistingZimFiles: Bool
    
    init(updateExistingZimFiles: Bool) {
        self.updateExistingZimFiles = updateExistingZimFiles
        super.init()
    }
    
    override func execute() {
        guard let data = input.value?.payload else {
            finish(withError: ProcedureKitError.requirementNotSatisfied())
            return
        }
        
        // prase xml
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        
        // update database
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            
            let predicate = NSPredicate(format: "NOT id IN %@ AND stateRaw == %@", Set(latest.keys), ZimFile.State.cloud.rawValue)
            let oldZimFiles = database.objects(ZimFile.self).filter(predicate)
            
            try database.write {
                // remove old zim files from database
                oldZimFiles.forEach({ database.delete($0) })
                
                for (zimFileID, meta) in latest {
                    if let zimFile = database.object(ofType: ZimFile.self, forPrimaryKey: zimFileID) {
                        guard updateExistingZimFiles else {continue}
                        // update existing zim files
                        update(zimFile: zimFile, meta: meta)
                    } else {
                        // add new zim files to database
                        let zimFile = create(database: database, id: zimFileID, meta: meta)
                        zimFile.state = .cloud
                    }
                }
            }
        } catch {
            finish(withError: error)
        }
        
        // apply language filter if library has never been refreshed
        if Defaults[.libraryLastRefreshTime] == nil, let code = Locale.current.languageCode {
            Defaults[.libraryFilterLanguageCodes] = [code]
        }
        
        // update last library refresh time
        Defaults[.libraryLastRefreshTime] = Date()
        finish()
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        guard elementName == "book", let zimFileID = attributeDict["id"] else {return}
        latest[zimFileID] = attributeDict
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        finish(withError: parseError)
    }
}

