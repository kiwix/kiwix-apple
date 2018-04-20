//
//  SearchQueue.swift
//  iOS
//
//  Created by Chris Li on 4/18/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import ProcedureKit

class SearchQueue: ProcedureQueue, ProcedureQueueDelegate {
    weak var eventDelegate: SearchQueueEvents?
    
    override init() {
        super.init()
        delegate = self
        maxConcurrentOperationCount = 1
    }
    
    func enqueue(searchText: String, zimFileIDs: Set<ZimFileID>) {
        let procedure = SearchProcedure(term: searchText, ids: zimFileIDs)
        add(operation: procedure)
    }
    
    func procedureQueue(_ queue: ProcedureQueue, willAddProcedure procedure: Procedure, context: Any?) -> ProcedureFuture? {
        if queue.operationCount == 0 {
            DispatchQueue.main.async {
                self.eventDelegate?.searchStarted()
            }
        } else {
            queue.operations.forEach({ $0.cancel() })
        }
        return nil
    }
    
    func procedureQueue(_ queue: ProcedureQueue, didFinishProcedure procedure: Procedure, withErrors errors: [Error]) {
        guard queue.operationCount == 0, let procedure = procedure as? SearchProcedure else {return}
        DispatchQueue.main.async {
            self.eventDelegate?.searchFinished(searchText: procedure.searchText, results: procedure.sortedResults)
        }
    }
}

protocol SearchQueueEvents: class {
    func searchStarted()
    func searchFinished(searchText: String, results: [SearchResult])
}
