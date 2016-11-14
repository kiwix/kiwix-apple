//
//  SearchOperation.swift
//  Kiwix
//
//  Created by Chris Li on 9/12/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import CoreData
import ProcedureKit

class SearchOperation: GroupProcedure {
    fileprivate(set) var results = [SearchResult]()
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

private class BookSearch: Procedure {
    let zimID: String
    let searchTerm: String
    fileprivate var results = [SearchResult]()
    
    init(zimID: String, searchTerm: String) {
        self.zimID = zimID
        self.searchTerm = searchTerm
        super.init()
    }
    
    override fileprivate func execute() {
        defer { finish() }
        guard let reader = ZimMultiReader.shared.readers[zimID] else {return}
        
        guard !isCancelled else {return}
        let indexedDics = reader.search(usingIndex: searchTerm) as? [[String: AnyObject]] ?? [[String: AnyObject]]()
        
        guard !isCancelled else {return}
        let titleDics = reader.searchSuggestionsSmart(searchTerm) as? [[String: AnyObject]] ?? [[String: AnyObject]]()
        
        guard !isCancelled else {return}
        let mixedDics = titleDics + indexedDics // It is important we process the title search result first, so that we always keep the indexed search result
        for dic in mixedDics {
            guard let result = SearchResult (rawResult: dic, lowerCaseSearchTerm: searchTerm) else {continue}
            self.results.append(result)
        }
    }
}

private class Sort: Procedure, AutomaticInjectionOperationType {
    var requirement = [SearchResult]()
    
    fileprivate override func execute() {
        defer { finish() }
        guard !isCancelled else {return}
        sort()
    }
    
    fileprivate func sort() {
        requirement.sort { (result0, result1) -> Bool in
            if result0.score != result1.score {
                return result0.score < result1.score
            } else {
                if result0.snippet != nil {return true}
                if result1.snippet != nil {return false}
                return titleCaseInsensitiveCompare(result0, result1: result1)
            }
        }
    }
    
    fileprivate func titleCaseInsensitiveCompare(_ result0: SearchResult, result1: SearchResult) -> Bool {
        return result0.title.caseInsensitiveCompare(result1.title) == ComparisonResult.orderedAscending
    }
}
