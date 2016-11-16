//
//  GlobalQueue.swift
//  Kiwix
//
//  Created by Chris Li on 5/14/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import ProcedureKit

class GlobalQueue: ProcedureQueue {
    static let shared = GlobalQueue()
    
    private weak var scanOperation: ScanLocalBookOperation?
    func add(scanOperation: ScanLocalBookOperation) {
        add(operation: scanOperation)
        self.scanOperation = scanOperation
    }
    
    private weak var searchOperation: SearchOperation?
    func add(searchOperation: SearchOperation) {
        if let scanOperation = scanOperation {
            searchOperation.addDependency(scanOperation)
        }
        
        if let searchOperation = self.searchOperation {
            searchOperation.cancel()
        }
        add(operation: searchOperation)
        self.searchOperation = searchOperation
    }

    // Fix: use specific class type
//    private weak var scanOperation: Procedure?
//    private weak var searchOperation: Procedure?
//    private weak var articleLoadOperation: ArticleLoadOperation?
    
//    func add(scan operation: Procedure) {
//        addOperation(operation)
//        scanOperation = operation
//    }
//    
//
//    func add(load operation: ArticleLoadOperation) {
//        if let scanOperation = scanOperation {
//            operation.addDependency(scanOperation)
//        }
//        
//        if let articleLoadOperation = self.articleLoadOperation {
//            operation.addDependency(articleLoadOperation)
//        }
//        
//        addOperation(operation)
//        articleLoadOperation = operation
//    }
}
