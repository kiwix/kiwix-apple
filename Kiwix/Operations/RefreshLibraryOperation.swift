//
//  RefreshLibraryOperation.swift
//  Kiwix
//
//  Created by Chris Li on 2/7/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import CoreData
import ProcedureKit

class RefreshLibraryOperation: GroupOperation {
    
    fileprivate(set) var hasUpdate = false
    fileprivate(set) var firstTime = false
    
    init(invokedByUser: Bool = false) {
        let retrieve = Retrieve()
        let process = Process()
        process.injectResultFromDependency(retrieve)
        super.init(operations: [retrieve, process])
        
        addObserver(NetworkObserver())
        if UIApplication.sharedApplication().applicationState == .Active {
            add(ReachabilityCondition(url: Retrieve.url))
        }
        
        addObserver(WillExecuteObserver { _ in
            (UIApplication.sharedApplication().delegate as! AppDelegate).registerNotification()
        })
        
        process.addObserver(DidFinishObserver { [unowned self] (operation, errors) in
            guard let operation = operation as? Process else {return}
            self.hasUpdate = operation.hasUpdate
            self.firstTime = operation.firstTime
        })
    }
}

private class Retrieve: Procedure, ResultOperationType {
    fileprivate static let url = URL(string: "https://download.kiwix.org/library/library.xml")!
    fileprivate var result: Data?
    
    override init() {
        super.init()
        name = "Library Retrieve"
    }
    
    fileprivate override func execute() {
        guard !isCancelled else {return}
        let task = URLSession.shared.dataTask(with: Retrieve.url, completionHandler: { (data, response, error) in
            self.result = data
            self.finish()
        }) 
        task.resume()
    }
}

private class Process: Procedure, XMLParserDelegate, AutomaticInjectionOperationType {
    var requirement: Data?
    fileprivate(set) var hasUpdate = false
    fileprivate(set) var firstTime = false
    fileprivate let context: NSManagedObjectContext
    fileprivate var oldBookIDs = Set<String>()
    fileprivate var newBookIDs = Set<String>()
    
    override init() {
        self.context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = NSManagedObjectContext.mainQueueContext
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        super.init()
        name = "Library Process"
    }
    
    override fileprivate func execute() {
        guard let data = requirement else {finish(); return}
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = self
        xmlParser.parse()
        finish()
    }
    
    fileprivate func saveManagedObjectContexts() {
        context.performAndWait { self.context.saveIfNeeded() }
        context.parent?.performAndWait { self.context.parent?.saveIfNeeded() }
    }
    
    // MARK: NSXMLParser Delegate
    
    @objc fileprivate func parserDidStartDocument(_ parser: XMLParser) {
        context.performAndWait { () -> Void in
            self.oldBookIDs = Set(Book.fetchAll(self.context).flatMap({ $0.id }))
        }
    }
    
    @objc fileprivate func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        guard elementName == "book",
            let id = attributeDict["id"] else {return}
        
        if !oldBookIDs.contains(id) {
            hasUpdate = true
            context.performAndWait({ () -> Void in
                Book.add(attributeDict, context: self.context)
            })
        }
        newBookIDs.insert(id)
    }
    
    @objc fileprivate func parserDidEndDocument(_ parser: XMLParser) {
        let idsToDelete = oldBookIDs.subtracting(newBookIDs)
        
        context.performAndWait({ () -> Void in
            idsToDelete.forEach({ (id) in
                guard let book = Book.fetch(id, context: self.context) else {return}
                
                // Delete Book object only if book is online, i.e., is not associated with a download task or is not local
                guard book.state == .cloud else {return}
                self.context.delete(book)
                self.hasUpdate = true
            })
        })
        
        saveManagedObjectContexts()
        firstTime = Preference.libraryLastRefreshTime == nil
        Preference.libraryLastRefreshTime = Date()
    }
    
    @objc fileprivate func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        saveManagedObjectContexts()
    }
}
