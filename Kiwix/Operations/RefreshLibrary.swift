//
//  RefreshLibrary.swift
//  Kiwix
//
//  Created by Chris Li on 11/8/16.
//  Copyright © 2016 Wikimedia CH. All rights reserved.
//

import ProcedureKit

class RefreshLibrary: GroupProcedure {
    
    init() {
        let retrieve = Retrieve()
        let process = Process()
        process.injectResult(from: retrieve)
        super.init(operations: [retrieve, process])
    }
    
}

private class Retrieve: NetworkDataProcedure<URLSession> {
    
    init() {
        let session = URLSession.shared
        let url = URL(string: "https://download.kiwix.org/library/library.xml")!
        let request = URLRequest(url: url)
        super.init(session: session, request: request)
    }
}

private class Process: Procedure, ResultInjection, XMLParserDelegate {
    var requirement: PendingValue<HTTPResult<Data>> = .pending
    var result: PendingValue<Void> = .void
    
    override func execute() {
        guard let data = requirement.value?.payload else {
            finish(withError: ProcedureKitError.requirementNotSatisfied())
            return
        }
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        
        finish()
    }
    
    func parserDidStartDocument(_ parser: XMLParser) {
//        let ids = Book.fetch(all: <#T##NSManagedObjectContext#>)
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        print(attributeDict["id"])
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        
    }
}
