//
//  SearchProcedure.swift
//  Kiwix
//
//  Created by Chris Li on 8/28/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import ProcedureKit

class SearchProcedure: Procedure {
    
    let term: String
    private(set) var results: [SearchResult] = []
    
    init(term: String) {
        self.term = term
        super.init()
        name = "Search Procedure"
    }
    
    override func execute() {
        defer {finish()}
        
        guard term != "" else {return}
        
        var results = indexedSearch()
        if results.count == 0 {
            results = titleSearch()
        }

        self.results = results
    }
    
    func indexedSearch() -> [SearchResult] {
        defer {ZimManager.shared.stopSearch()}
        
        guard !isCancelled else {return []}
        var results = [SearchResult]()
        ZimManager.shared.startSearch(term: term)
        while let result = ZimManager.shared.getNextSearchResult() {
            guard !isCancelled else {return []}
            results.append(result)
        }
        return results
    }
    
    func titleSearch() -> [SearchResult]{
        guard !isCancelled else {return []}
        return ZimManager.shared.getSearchSuggestions(term: term)
    }
}
