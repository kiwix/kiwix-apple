//
//  LibraryRefreshProcedure.swift
//  Kiwix
//
//  Created by Chris Li on 10/18/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import CoreData
import ProcedureKit
import SwiftyUserDefaults

class LibraryRefreshProcedureNew: Procedure {
    let progress = Progress(totalUnitCount: 100)
    private let processingProgress = Progress()
    
    override func execute() {
        let request: URLRequest = {
            let url = URL(string: "https://download.kiwix.org/library/library_zim.xml")!
            var request = URLRequest(url: url)
            request.timeoutInterval = 30.0
            return request
        }()
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            NetworkActivityController.shared.taskDidFinish(identifier: "LibraryRefreshProcedure")
            if let error = error {
                self.finish(withError: error)
            } else if let data = data {
                let context = PersistentContainer.shared.newBackgroundContext()
                let processor = LibraryXMLProcessor(data: data, context: context, isOverwriting: false)
                processor.parser.parse()
            }
        }
        if #available(iOS 11.0, *) {
            progress.addChild(task.progress, withPendingUnitCount: 40)
        }
        NetworkActivityController.shared.taskDidStart(identifier: "LibraryRefreshProcedure")
        task.resume()
    }
}

private class LibraryXMLProcessor: NSObject, XMLParserDelegate {
    let parser: XMLParser
    let context: NSManagedObjectContext
    
    init(data: Data, context: NSManagedObjectContext, isOverwriting: Bool) {
        self.parser = XMLParser(data: data)
        self.context = context
        
        super.init()
        parser.delegate = self
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
    }
}

class BookMetaDataParser {
    class func getArticleCount(attributes: [String : String]) -> Int64 {
        guard let string = attributes["articleCount"], let value = Int64(string) else {return 0}
        return value
    }
    
    class func getMediaCount(attributes: [String : String]) -> Int64 {
        guard let string = attributes["mediaCount"], let value = Int64(string) else {return 0}
        return value
    }
    
    class func getFileSize(attributes: [String : String]) -> Int64 {
        guard let string = attributes["size"], let value = Int64(string) else {return 0}
        return value * 1024
    }
}




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
    private let context: NSManagedObjectContext
    
    private var storeBookIDs = Set<String>()
    private var memoryBookIDs = Set<String>()
    
    private(set) var hasUpdate = false
    
    override init() {
        self.context = PersistentContainer.shared.newBackgroundContext()
        super.init()
    }
    
    override func execute() {
        guard let data = input.value?.payload else {
            finish(withError: ProcedureKitError.requirementNotSatisfied())
            return
        }
        
        context.performAndWait {
            storeBookIDs = Set(Book.fetchAll(context: context).map({ $0.id }))
            
            let parser = XMLParser(data: data)
            parser.delegate = self
            parser.parse()
            
            let toBeDeleted = storeBookIDs.subtracting(memoryBookIDs)
            hasUpdate = toBeDeleted.count > 0 || hasUpdate
            
            for id in toBeDeleted {
                guard let book = Book.fetch(id: id, context: self.context), book.state == .cloud else {continue}
                self.context.delete(book)
            }
            if context.hasChanges { try? context.save() }
        }
        
        Defaults[.libraryLastRefreshTime] = Date()
        finish()
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        guard elementName == "book", let id = attributeDict["id"] else {return}
        if !storeBookIDs.contains(id) {
            hasUpdate = true
            context.performAndWait({
                self.addBook(meta: attributeDict, in: self.context)
            })
        }
        memoryBookIDs.insert(id)
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        finish(withError: parseError)
    }
    
    func addBook(meta: [String: String], in context: NSManagedObjectContext) {
        guard let id = meta["id"] else {return}
        let book = Book(context: context)
        
        book.id = id
        book.title = meta["title"]
        book.creator = meta["creator"]
        book.publisher = meta["publisher"]
        book.bookDescription = meta["description"]
        book.meta4URL = meta["url"]
        book.pid = meta["name"]
        
        book.articleCount = BookMetaDataParser.getArticleCount(attributes: meta)
        book.mediaCount = BookMetaDataParser.getMediaCount(attributes: meta)
        book.fileSize = BookMetaDataParser.getFileSize(attributes: meta)
        book.category = {
            guard let urlString = meta["url"],
                let components = URL(string: urlString)?.pathComponents,
                components.indices ~= 2 else {return nil}
            if let category = BookCategory(rawValue: components[2]) {
                return category.rawValue
            } else if components[2] == "stack_exchange" {
                return BookCategory.stackExchange.rawValue
            } else {
                return BookCategory.other.rawValue
            }
        }()
        
        book.date = {
            guard let date = meta["date"] else {return nil}
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            return dateFormatter.date(from: date)
        }()
        
        book.favIcon = {
            guard let favIcon = meta["favicon"] else {return nil}
            return Data(base64Encoded: favIcon, options: .ignoreUnknownCharacters)
        }()
        
        book.hasPic = {
            if let tags = meta["tags"], tags.contains("nopic") {
                return false
            } else if let meta4url = book.meta4URL, meta4url.contains("nopic") {
                return false
            } else {
                return true
            }
        }()
        
        book.hasIndex = {
            if let tags = meta["tags"], tags.contains("_ftindex") {
                return true
            } else {
                return false
            }
        }()
        
        book.language = {
            guard let languageCode = meta["language"],
                let language = Language.fetchOrAdd(languageCode, context: context) else {return nil}
            return language
        }()
    }
}

