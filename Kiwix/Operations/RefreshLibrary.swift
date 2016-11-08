//
//  RefreshLibrary.swift
//  Kiwix
//
//  Created by Chris Li on 11/8/16.
//  Copyright © 2016 Wikimedia CH. All rights reserved.
//

import ProcedureKit
import CoreData

class RefreshLibraryOperation: GroupProcedure {
    
    init() {
        let retrieve = Retrieve()
        let process = Process()
        process.injectResult(from: retrieve)
        super.init(operations: [retrieve, process])
    }
    
}

fileprivate class Retrieve: NetworkDataProcedure<URLSession> {
    init() {
        let session = URLSession.shared
        let url = URL(string: "https://download.kiwix.org/library/library.xml")!
        let request = URLRequest(url: url)
        super.init(session: session, request: request)
    }
}

fileprivate class Process: Procedure, ResultInjection, XMLParserDelegate {
    var requirement: PendingValue<HTTPResult<Data>> = .pending
    fileprivate(set) var result: PendingValue<Void> = .void
    private let context: NSManagedObjectContext
    
    private var storeBookIDs = Set<String>()
    private var memoryBookIDs = Set<String>()
    
    private var hasUpdate = false
    
    override init() {
        self.context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = AppDelegate.persistentContainer.viewContext
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        super.init()
    }
    
    override func execute() {
        guard let data = requirement.value?.payload else {
            finish(withError: ProcedureKitError.requirementNotSatisfied())
            return
        }
        
        storeBookIDs = Set(Book.fetchAll(in: context).map({ $0.id }))
        
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        
        let toBeDeleted = storeBookIDs.subtracting(memoryBookIDs)
        hasUpdate = toBeDeleted.count > 0
        context.performAndWait {
            toBeDeleted.forEach({ (id) in
                
            })
        }
        print("\(memoryBookIDs.count)")
        
        if context.hasChanges { try? context.save() }
        finish()
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        guard elementName == "book", let id = attributeDict["id"] else {return}
        if !storeBookIDs.contains(id) {
            hasUpdate = true
            context.performAndWait({ 
                _ = Book.add(meta: attributeDict, in: self.context)
            })
        }
        memoryBookIDs.insert(id)
    }
}
