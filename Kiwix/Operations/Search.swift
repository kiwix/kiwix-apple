//
//  Search.swift
//  Kiwix
//
//  Created by Chris Li on 11/15/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import ProcedureKit

class SearchOperation: GroupProcedure {
    private(set) var results = [SearchResult]()
    let searchText: String
    
    init(searchText: String) {
        self.searchText = searchText
        super.init(operations: [])
        add(condition: MutuallyExclusive<SearchContainer>())
        
        let searches = Book.fetchLocal(in: AppDelegate.persistentContainer.viewContext)
            .filter({ $0.includeInSearch })
            .map({ BookSearch(zimID: $0.id, searchText: searchText) })
        let sort = Sort()
        searches.forEach { (search) in
            sort.inject(dependency: search, block: { (sort, search, errors) in
                sort.results += search.results
            })
        }
        sort.add(observer: DidFinishObserver { [unowned self] (operation, errors) in
            guard let sort = operation as? Sort else {return}
            self.results = sort.results
        })
        add(children: searches)
        add(children: sort)
    }
}

private class BookSearch: Procedure {
    let zimID: ZimID
    let searchText: String
    
    fileprivate var results = [SearchResult]()
    
    init(zimID: ZimID, searchText: String) {
        self.zimID = zimID
        self.searchText = searchText
        super.init()
    }
    
    fileprivate override func execute() {
        defer { finish() }
        guard let reader = ZimMultiReader.shared.readers[zimID] else {return}
        
        guard !isCancelled else {return}
        let indexedDics = reader.search(usingIndex: searchText) as? [[String: AnyObject]] ?? [[String: AnyObject]]()
        
        guard !isCancelled else {return}
        let titleDics = reader.searchSuggestionsSmart(searchText) as? [[String: AnyObject]] ?? [[String: AnyObject]]()
        
        guard !isCancelled else {return}
        // It is important we process the title search result first, so that we always keep the indexed search result
        let mixedDics = titleDics + indexedDics
        for dic in mixedDics {
            guard let result = SearchResult (rawResult: dic, lowerCaseSearchTerm: searchText) else {continue}
            self.results.append(result)
        }
    }
}

private class Sort: Procedure {
    fileprivate var results = [SearchResult]()
    
    fileprivate override func execute() {
        defer { finish() }
        guard !isCancelled else {return}
        results.sort { (result0, result1) -> Bool in
            if result0.score != result1.score {
                return result0.score < result1.score
            } else {
                if result0.snippet != nil {return true}
                if result1.snippet != nil {return false}
                return result0 << result1
            }
        }
    }
}
