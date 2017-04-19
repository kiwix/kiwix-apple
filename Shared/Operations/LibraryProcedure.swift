//
//  RefreshLibrary.swift
//  Kiwix
//
//  Created by Chris Li on 11/8/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import ProcedureKit
import CoreData

class RefreshLibraryOperation: GroupProcedure {
    private(set) var hasUpdate = false
    private(set) var firstTime = Preference.libraryLastRefreshTime == nil
    
    init() {
        let retrieve = Retrieve()
        let process = Process()
        process.injectResult(from: retrieve)
        super.init(operations: [retrieve, process])
        
        process.add(observer: DidFinishObserver { [unowned self] (operation, error) in
            guard let process = operation as? Process else {return}
            self.hasUpdate = process.hasUpdate
        })
    }
}

private class Retrieve: NetworkDataProcedure<URLSession> {
    init() {
        let session = URLSession.shared
        let url = URL(string: "https://download.kiwix.org/library/library_zim.xml")!
        var request = URLRequest(url: url)
        request.timeoutInterval = 30.0
        super.init(session: session, request: request)
        
        addWillExecuteBlockObserver { _ in
            NetworkActivityController.shared.taskDidStart(identifier: "RetrieveLibrary")
        }
        addDidFinishBlockObserver { _ in
            NetworkActivityController.shared.taskDidFinish(identifier: "RetrieveLibrary")
        }
    }
}

private class Process: Procedure, InputProcedure, XMLParserDelegate {
    var input: Pending<HTTPPayloadResponse<Data>> = .pending
    private let context: NSManagedObjectContext
    
    private var storeBookIDs = Set<String>()
    private var memoryBookIDs = Set<String>()
    
    private(set) var hasUpdate = false
    
    override init() {
        self.context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = AppDelegate.persistentContainer.viewContext
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
        hasUpdate = toBeDeleted.count > 0
        context.performAndWait {
            for id in toBeDeleted {
                guard let book = Book.fetch(id, context: self.context) else {continue}
                self.context.delete(book)
            }
        }
        
        if context.hasChanges { try? context.save() }
        Preference.libraryLastRefreshTime = Date()
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
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        finish(withError: parseError)
    }
}
