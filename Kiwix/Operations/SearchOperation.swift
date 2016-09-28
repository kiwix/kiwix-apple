//
//  SearchOperation.swift
//  Kiwix
//
//  Created by Chris Li on 9/12/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import CoreData
import Operations

class SearchOperation: GroupOperation {
    private(set) var results = [SearchResult]()
    let searchTerm: String
    
    init(searchTerm: String) {
        self.searchTerm = searchTerm
        super.init(operations: [])
    }
    
    override func execute() {
        let searches = Book.fetchLocal(NSManagedObjectContext.mainQueueContext)
            .filter({ $1.includeInSearch })
            .map({ BookSearch(zimID: $1.id, searchTerm: searchTerm) })
        let sort = Sort()
        searches.forEach { (search) in
            sort.injectResultFromDependency(search, block: { (operation, dependency, errors) in
                operation.requirement += dependency.results
            })
        }
        
        sort.addObserver(DidFinishObserver { [unowned self] (operation, errors) in
            guard let operation = operation as? Sort else {return}
            self.results = operation.requirement
            })
        
        addOperations(searches)
        addOperation(sort)
        
        super.execute()
    }
}

private class BookSearch: Operation {
    let zimID: String
    let searchTerm: String
    private var results = [SearchResult]()
    
    init(zimID: String, searchTerm: String) {
        self.zimID = zimID
        self.searchTerm = searchTerm
        super.init()
    }
    
    override private func execute() {
        defer { finish() }
        guard let reader = ZimMultiReader.shared.readers[zimID] else {return}
        
        guard !cancelled else {return}
        let indexedDics = reader.searchUsingIndex(searchTerm) as? [[String: AnyObject]] ?? [[String: AnyObject]]()
        
        guard !cancelled else {return}
        let titleDics = reader.searchSuggestionsSmart(searchTerm) as? [[String: AnyObject]] ?? [[String: AnyObject]]()
        
        guard !cancelled else {return}
        let mixedDics = titleDics + indexedDics // It is important we process the title search result first, so that we always keep the indexed search result
        for dic in mixedDics {
            guard let result = SearchResult (rawResult: dic, lowerCaseSearchTerm: searchTerm) else {continue}
            self.results.append(result)
        }
    }
}

private class Sort: Operation, AutomaticInjectionOperationType {
    var requirement = [SearchResult]()
    
    private override func execute() {
        defer { finish() }
        guard !cancelled else {return}
        sort()
    }
    
    private func sort() {
        requirement.sortInPlace { (result0, result1) -> Bool in
            if result0.score != result1.score {
                return result0.score < result1.score
            } else {
                if result0.snippet != nil {return true}
                if result1.snippet != nil {return false}
                return titleCaseInsensitiveCompare(result0, result1: result1)
            }
        }
    }
    
    private func titleCaseInsensitiveCompare(result0: SearchResult, result1: SearchResult) -> Bool {
        return result0.title.caseInsensitiveCompare(result1.title) == NSComparisonResult.OrderedAscending
    }
}
