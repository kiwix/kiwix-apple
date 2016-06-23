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
            let managedObjectContext = UIApplication.appDelegate.managedObjectContext
            guard let book = Book.fetch(id, context: managedObjectContext) else {continue}
            guard book.includeInSearch else {continue}
            let operation = SingleBookSearchOperation(zimReader: zimReader,
                                                      searchTerm: searchTerm.lowercaseString,
                                                      completionHandler: { [unowned sortOperation] (results) in
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
    private var results = [String: SearchResult]()
    
    init(zimReader: ZimReader, searchTerm: String, completionHandler: ([SearchResult]) -> Void) {
        self.zimReader = zimReader
        self.searchTerm = searchTerm
        self.completionHandler = completionHandler
    }
    
    override private func execute() {
        let indexedDics = zimReader.searchUsingIndex(searchTerm) as? [[String: AnyObject]] ?? [[String: AnyObject]]()
        let titleDics = zimReader.searchSuggestionsSmart(searchTerm) as? [[String: AnyObject]] ?? [[String: AnyObject]]()
        let mixedDics = titleDics + indexedDics // It is important we process the title search result first, so that we always keep the indexed search result
        for dic in mixedDics {
            guard let result = SearchResult (rawResult: dic) else {continue}
            results[result.title] = result
        }
        completionHandler(Array(results.values))
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
        sort()
        completionHandler(results)
        finish()
    }
    
    /*
     1. Xapian results before searchSuggestionSmart results
     2. Among Xapian results: sort by percent, then title case insensitive compare
     3. Among searchSuggestionSmart results: sort by title case insensitive compare
    */
    private func sort() {
        results.sortInPlace { (result0, result1) -> Bool in
            if result0.score != result1.score {
                return result0.score < result1.score
            } else {
                return titleCaseInsensitiveCompare(result0, result1: result1)
            }
        }
    }
    
    // MARK: - Utilities
    
    private func titleCaseInsensitiveCompare(result0: SearchResult, result1: SearchResult) -> Bool {
        return result0.title.caseInsensitiveCompare(result1.title) == NSComparisonResult.OrderedAscending
    }
}

