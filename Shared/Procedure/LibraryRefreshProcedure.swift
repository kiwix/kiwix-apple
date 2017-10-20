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
        add(observer: NetworkObserver())
    }
}

private class ProcessProcedure: Procedure, InputProcedure, XMLParserDelegate {
    var input: Pending<HTTPPayloadResponse<Data>> = .pending
    private let context: NSManagedObjectContext
    
    private var storeBookIDs = Set<String>()
    private var memoryBookIDs = Set<String>()
    
    private(set) var hasUpdate = false
    
    override init() {
        self.context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = CoreDataContainer.shared.viewContext
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        super.init()
    }
    
    override func execute() {
        guard let data = input.value?.payload else {
            finish(withError: ProcedureKitError.requirementNotSatisfied())
            return
        }
        
        storeBookIDs = Set(Book.fetchAll(in: context).map({ $0.id }))
        
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        
        let toBeDeleted = storeBookIDs.subtracting(memoryBookIDs)
        hasUpdate = toBeDeleted.count > 0 || hasUpdate
        context.performAndWait {
            for id in toBeDeleted {
                guard let book = Book.fetch(id: id, context: self.context), book.state == .cloud else {continue}
                self.context.delete(book)
            }
        }
        
        if context.hasChanges { try? context.save() }
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
        book.desc = meta["description"]
        book.meta4URL = meta["url"]
        book.pid = meta["name"]
        
        book.articleCount = {
            guard let string = meta["articleCount"], let value = Int64(string) else {return 0}
            return value
        }()
        book.mediaCount = {
            guard let string = meta["mediaCount"], let value = Int64(string) else {return 0}
            return value
        }()
        book.fileSize = {
            guard let string = meta["size"], let value = Int64(string) else {return 0}
            return value * 1024
        }()
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
        
        book.language = {
            guard let languageCode = meta["language"],
                let language = Language.fetchOrAdd(languageCode, context: context) else {return nil}
            return language
        }()
    }
}

