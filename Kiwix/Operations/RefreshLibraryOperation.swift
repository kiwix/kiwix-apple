//
//  RefreshLibraryOperation.swift
//  Kiwix
//
//  Created by Chris Li on 2/7/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import CoreData
import Operations

class RefreshLibraryOperation: GroupOperation {
    
    init() {
        let retrive = Retrive()
        let process = Process()
        process.injectResultFromDependency(retrive)
        super.init(operations: [retrive, process])
    }

}

private class Retrive: Operation, ResultOperationType {
    private static let url = NSURL(string: "http://www.kiwix.org/library.xml")!
    private var result: NSData?
    
    override init() {
        super.init()
        addObserver(NetworkObserver())
        addCondition(ReachabilityCondition(url: Retrive.url, connectivity: .AnyConnectionKind))
    }
    
    private override func execute() {
        let task = NSURLSession.sharedSession().dataTaskWithURL(Retrive.url) { (data, response, error) in
            self.result = data
            self.finish()
        }
        task.resume()
    }
}

private class Process: Operation, NSXMLParserDelegate, AutomaticInjectionOperationType {
    var requirement: NSData?
    private let context: NSManagedObjectContext
    private var oldBookIDs = Set<String>()
    private var newBookIDs = Set<String>()
    
    override init() {
        self.context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        context.parentContext = NSManagedObjectContext.mainQueueContext
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        super.init()
    }
    
    override private func execute() {
        guard let data = requirement else {finish(); return}
        let xmlParser = NSXMLParser(data: data)
        xmlParser.delegate = self
        xmlParser.parse()
        finish()
    }
    
    private func saveManagedObjectContexts() {
        context.performBlockAndWait { self.context.saveIfNeeded() }
        context.parentContext?.performBlockAndWait { self.context.parentContext?.saveIfNeeded() }
    }
    
    // MARK: NSXMLParser Delegate
    
    @objc private func parserDidStartDocument(parser: NSXMLParser) {
        context.performBlockAndWait { () -> Void in
            self.oldBookIDs = Set(Book.fetchAll(self.context).flatMap({ $0.id }))
        }
    }
    
    @objc private func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        guard elementName == "book",
            let id = attributeDict["id"] else {return}
        
        if !oldBookIDs.contains(id) {
            context.performBlockAndWait({ () -> Void in
                Book.add(attributeDict, context: self.context)
            })
        }
        newBookIDs.insert(id)
    }
    
    @objc private func parserDidEndDocument(parser: NSXMLParser) {
        let idsToDelete = oldBookIDs.subtract(newBookIDs)
        
        context.performBlockAndWait({ () -> Void in
            idsToDelete.forEach({ (id) in
                guard let book = Book.fetch(id, context: self.context) else {return}
                
                // Delete Book object only if book is online, i.e., is not associated with a download task or is not local
                guard book.isLocal == false else {return}
                self.context.deleteObject(book)
            })
        })
        
        saveManagedObjectContexts()
        Preference.libraryLastRefreshTime = NSDate()
    }
    
    @objc private func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError) {
        saveManagedObjectContexts()
    }
}
