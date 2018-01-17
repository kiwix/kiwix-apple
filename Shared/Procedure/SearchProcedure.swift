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
    let ids: [ZimFileID]
    private(set) var results: [SearchResult] = []
    
    init(term: String, ids: [ZimFileID] = []) {
        self.term = term
        self.ids = ids.count == 0 ? ZimMultiReader.shared.ids : ids
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
        defer {ZimMultiReader.shared.stopIndexSearch()}
        
        guard !isCancelled else {return []}
        var results = [SearchResult]()
        ZimMultiReader.shared.startIndexSearch(term: term)
        while let result = ZimMultiReader.shared.getNextIndexSearchResult() {
            guard !isCancelled else {return []}
            results.append(result)
        }
        return results
    }
    
    func titleSearch() -> [SearchResult]{
        guard !isCancelled else {return []}
        return ZimMultiReader.shared.getTitleSearchResults(term: term)
    }
}
