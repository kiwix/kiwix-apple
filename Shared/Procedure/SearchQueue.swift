//
//  SearchQueue.swift
//  iOS
//
//  Created by Chris Li on 4/18/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import ProcedureKit
import SwiftyUserDefaults

class SearchQueue: ProcedureQueue {
    weak var eventDelegate: SearchQueueEvents?
    private var operationsObserver: NSKeyValueObservation?
    
    override init() {
        super.init()
        maxConcurrentOperationCount = 1
        operationsObserver = observe(\.operations, options: [.new, .old], changeHandler: { (operation, change) in
            guard let oldOperations = change.oldValue, let newOperations = change.newValue else {return}
            if (newOperations.count > oldOperations.count) {
                // did start search
                guard oldOperations.count == 0 else {return}
                DispatchQueue.main.async {
                    self.eventDelegate?.searchStarted()
                }
            } else {
                // did finish search operation
                guard newOperations.count == 0, let operation = oldOperations.last as? SearchProcedure else {return}
                DispatchQueue.main.async {
                    if operation.isCancelled {
                        self.eventDelegate?.searchFinished(searchText: "", results: [])
                    } else {
                        self.eventDelegate?.searchFinished(searchText: operation.searchText, results: operation.sortedResults)
                    }
                }
            }
        })
    }
    
    func enqueue(searchText: String, zimFileIDs: Set<ZimFileID>) {
        cancelAllOperations()
        let procedure = SearchProcedure(term: searchText, ids: zimFileIDs, extractSnippet: !Defaults[.searchResultExcludeSnippet])
        addOperation(procedure)
    }
}

protocol SearchQueueEvents: class {
    func searchStarted()
    func searchFinished(searchText: String, results: [SearchResult])
}
