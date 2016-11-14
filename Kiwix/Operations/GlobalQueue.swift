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
    
    // Fix: use specific class type
//    private weak var scanOperation: Procedure?
//    private weak var searchOperation: Procedure?
//    private weak var articleLoadOperation: ArticleLoadOperation?
    
//    func add(scan operation: Procedure) {
//        addOperation(operation)
//        scanOperation = operation
//    }
//    
//    func add(search operation: Procedure) {
//        if let scanOperation = scanOperation {
//            operation.addDependency(scanOperation)
//        }
//        
//        if let searchOperation = self.searchOperation {
//            searchOperation.cancel()
//        }
//        addOperation(operation)
//        searchOperation = operation
//    }
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
