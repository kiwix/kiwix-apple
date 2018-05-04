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
    init() {
        let download = DownloadProcedure()
        let process = ProcessProcedure()
        process.injectResult(from: download)
        super.init(operations: [download, process])
    }
}

private class DownloadProcedure: NetworkDataProcedure<URLSession> {
    init() {
        let session = URLSession.shared
        let url = URL(string: "https://download.kiwix.org/library/library_zim.xml")!
        var request = URLRequest(url: url)
        request.timeoutInterval = 30.0
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
    
    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()
    
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
                
                // add new zim files to database
                for (zimFileID, meta) in latest {
                    guard database.object(ofType: ZimFile.self, forPrimaryKey: zimFileID) == nil else {continue}
                    
                    let zimFile = createZimFile(database: database, meta: meta)
                    zimFile.state = .cloud
                    print(zimFile)
                }
            }
        } catch {
            finish(withError: error)
        }
        
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

