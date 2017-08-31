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
        add(condition: MutuallyExclusive<SearchController>())
        name = "Search Procedure"
    }
    
    override func execute() {
        defer {
            finish()
        }
        
        guard term != "" else {return}
        var results = [SearchResult]()
        
        ZimManager.shared.startSearch(term: term)
        while let result = ZimManager.shared.getNextSearchResult() {
            guard !isCancelled else {return}
            results.append(result)
        }
        ZimManager.shared.stopSearch()
        
        guard !isCancelled else {return}
        if results.count == 0 {
            results += ZimManager.shared.getSearchSuggestions(term: term)
        }
        
        self.results = results
    }
}
