//
//  RefreshLibraryOperation.swift
//  Kiwix
//
//  Created by Chris Li on 2/7/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import CoreData
import PSOperations

class RefreshLibraryOperation: GroupOperation {
    
    var completionHandler: ((errors: [NSError]) -> Void)?
    
    init(invokedAutomatically: Bool, completionHandler: ((errors: [NSError]) -> Void)?) {
        super.init(operations: [])
        
        name = String(RefreshLibraryOperation)
        self.completionHandler = completionHandler
        
        // 1.Parse
        let parseOperation = ParseLibraryOperation()
        
        // 0.Download library
        let url = NSURL(string: "http://www.kiwix.org/library.xml")!
        let task = NSURLSession.sharedSession().dataTaskWithURL(url) { [unowned parseOperation] (data, response, error) -> Void in
            if let error = error {self.aggregateError(error)}
            parseOperation.xmlData = data
        }
        let fetchOperation = URLSessionTaskOperation(task: task)
        fetchOperation.name = "Library XML download operation"
        
        #if os(iOS) || os(watchOS) || os(tvOS)
            fetchOperation.addObserver(NetworkObserver())
        #endif
        fetchOperation.addCondition(ReachabilityCondition(host: url, allowCellular: Preference.libraryRefreshAllowCellularData))
        
        if invokedAutomatically {
            addCondition(AllowAutoRefreshCondition())
        }
        
        addOperation(fetchOperation)
        addOperation(parseOperation)
        parseOperation.addDependency(fetchOperation)
    }
    
    override func finished(errors: [NSError]) {
        completionHandler?(errors: errors)
    }
}

class ParseLibraryOperation: Operation, NSXMLParserDelegate {
    var xmlData: NSData?
    let context: NSManagedObjectContext
    
    var oldBookIDs = Set<String>()
    var newBookIDs = Set<String>()
    
    override init() {
        self.context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        context.parentContext = NSManagedObjectContext.mainQueueContext
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        super.init()
        name = String(ParseLibraryOperation)
    }
    
    override func execute() {
        guard let data = xmlData else {finish(); return}
        let xmlParser = NSXMLParser(data: data)
        xmlParser.delegate = self
        xmlParser.parse()
        finish()
    }
    
    // MARK: NSXMLParser Delegate
    
    @objc internal func parserDidStartDocument(parser: NSXMLParser) {
        context.performBlockAndWait { () -> Void in
            self.oldBookIDs = Set(Book.fetchAll(self.context).map({$0.id ?? ""}))
        }
    }
    
    @objc internal func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        guard elementName == "book" else {return}
        guard let id = attributeDict["id"] else {return}
        
        if !oldBookIDs.contains(id) {
            context.performBlockAndWait({ () -> Void in
                Book.add(attributeDict, context: self.context)
            })
        }
        newBookIDs.insert(id)
    }
    
    @objc internal func parserDidEndDocument(parser: NSXMLParser) {
        // ID of Books on device but no longer in library.xml
        let ids = oldBookIDs.subtract(newBookIDs)
        
        for id in ids {
            context.performBlockAndWait({ () -> Void in
                guard let book = Book.fetch(id, context: self.context) else {return}
                
                // Delete Book object only if book is online, i.e., is not associated with a download task or is not local
                guard book.isLocal == false else {return}
                self.context.deleteObject(book)
            })
        }

        saveManagedObjectContexts()
        Preference.libraryLastRefreshTime = NSDate()
        //print("Parse finished successfully")
    }
    
    @objc internal func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError) {
        saveManagedObjectContexts()
    }
    
    // MARK: - Tools
    
    func saveManagedObjectContexts() {
        context.performBlockAndWait { () -> Void in
            self.context.saveIfNeeded()
        }
        context.parentContext?.performBlockAndWait({ () -> Void in
            self.context.parentContext?.saveIfNeeded()
        })
    }
}

private struct AllowAutoRefreshCondition: OperationCondition {
    static let name = "LibraryAllowAutoRefresh"
    static let isMutuallyExclusive = false
    
    init() {}
    
    func dependencyForOperation(operation: Operation) -> NSOperation? {
        return nil
    }
    
    func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        let allowAutoRefresh = !Preference.libraryAutoRefreshDisabled
        
        if allowAutoRefresh {
            completion(.Satisfied)
        } else {
            let error = NSError(code: .ConditionFailed, userInfo: [OperationConditionKey: self.dynamicType.name])
            completion(.Failed(error))
        }
    }
}