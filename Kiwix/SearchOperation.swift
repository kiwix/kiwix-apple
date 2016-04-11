//
//  SearchOperation.swift
//  Kiwix
//
//  Created by Chris Li on 4/9/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class SearchOperation: GroupOperation {
    let completionHandler: ([SearchResult]) -> Void
    private(set) var results = [SearchResult]()
    
    init(searchTerm: String, completionHandler: ([SearchResult]) -> Void) {
        self.completionHandler = completionHandler
        super.init(operations: [NSOperation]())
        
        let sortOperation = SortSearchResultsOperation { (results) in
            self.results = results
        }
        
        for (id, zimReader) in ZIMMultiReader.sharedInstance.readers {
            let operation = SingleBookSearchOperation(zimReader: zimReader, searchTerm: searchTerm, completionHandler: { [unowned sortOperation] (results) in
                sortOperation.results += results
            })
            
            addOperation(operation)
            sortOperation.addDependency(operation)
        }
        
        addOperation(sortOperation)
    }
    
    override func finished(errors: [NSError]) {
        NSOperationQueue.mainQueue().addOperationWithBlock { 
            self.completionHandler(self.results)
        }
    }
}

private class SingleBookSearchOperation: Operation {
    let zimReader: ZimReader
    let searchTerm: String
    let completionHandler: ([SearchResult]) -> Void
    
    init(zimReader: ZimReader, searchTerm: String, completionHandler: ([SearchResult]) -> Void) {
        self.zimReader = zimReader
        self.searchTerm = searchTerm
        self.completionHandler = completionHandler
    }
    
    override private func execute() {
        guard let resultDics = zimReader.search(searchTerm) as? [[String: AnyObject]] else {
            finish()
            return
        }
        var results = [SearchResult]()
        for dic in resultDics {
            guard let result = SearchResult(rawResult: dic) else {continue}
            results.append(result)
        }
        completionHandler(results)
        finish()
    }
}

private class SortSearchResultsOperation: Operation {
    let completionHandler: ([SearchResult]) -> Void
    var results = [SearchResult]()
    
    init(completionHandler: ([SearchResult]) -> Void) {
        self.completionHandler = completionHandler
    }
    
    override private func execute() {
        sortBySearchMethod()
        completionHandler(results)
        finish()
    }
    
    /*
     1. Xapian results before searchSuggestionSmart results
     2. Among Xapian results: sort by percent, then title case insensitive compare
     3. Among searchSuggestionSmart results: sort by title case insensitive compare
    */
    private func sortBySearchMethod() {
        results.sortInPlace { (result0, result1) -> Bool in
            let result0Percent = result0.percent ?? -1
            let result1Percent = result1.percent ?? -1
            if result0Percent == result1Percent {
                return titleCaseInsensitiveCompare(result0, result1: result1)
            } else {
                return result0Percent > result1Percent
            }
        }
    }
    
    // MARK: - Utilities
    
    private func titleCaseInsensitiveCompare(result0: SearchResult, result1: SearchResult) -> Bool {
        return result0.title.caseInsensitiveCompare(result1.title) == NSComparisonResult.OrderedAscending
    }
}

