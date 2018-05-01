//
//  LibraryRefreshProcedure.swift
//  Kiwix
//
//  Created by Chris Li on 10/18/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import CoreData
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

private class ProcessProcedure: Procedure, InputProcedure, XMLParserDelegate {
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
                    
                    var meta = meta
                    clean(meta: &meta)
                    let zimFile = ZimFile(value: meta)
                    database.add(zimFile)
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
    
    private func clean( meta: inout [String: Any]) {
        meta["pid"] = meta["name"]
        meta["bookDescription"] = meta["description"]
        
        if let language = meta["language"] as? String {
            meta["languageCode"] = Locale.canonicalLanguageIdentifier(from: language)
        }
        
        if let date = meta["date"] as? String {
            meta["creationDate"] = dateFormatter.date(from: date)
        }
        
        if let articleCount = meta["articleCount"] as? String, let count = Int64(articleCount) {
            meta["articleCount"] = count
        }
        
        if let mediaCount = meta["mediaCount"] as? String, let count = Int64(mediaCount) {
            meta["mediaCount"] = count
        }
        if let size = meta["size"] as? String, let fileSize = Int64(size) {
            meta["fileSize"] = fileSize * 1024
        }
        
        if let tags = meta["tags"] as? String {
            meta["hasPicture"] = !tags.contains("nopic")
            meta["hasEmbeddedIndex"] = tags.contains("_ftindex")
        }
        
        if let favIcon = meta["favicon"] as? String, let icon = Data(base64Encoded: favIcon, options: .ignoreUnknownCharacters) {
            meta["icon"] = icon
        }
        
        meta["remoteURL"] = meta["url"]
    }
}

