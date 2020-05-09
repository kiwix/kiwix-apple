//
//  SearchProcedure.swift
//  Kiwix
//
//  Created by Chris Li on 8/28/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import SwiftyUserDefaults

class SearchProcedure: Operation {
    let searchText: String
    let ids: Set<ZimFileID>
    let extractSnippet: Bool
    
    private var results = Set<SearchResultDeprecated>()
    private(set) var sortedResults: [SearchResultDeprecated] = []
    
    init(term: String, ids: Set<ZimFileID> = Set(), extractSnippet: Bool? = nil) {
        self.searchText = term
        self.ids = ids.count == 0 ? Set(ZimMultiReader.shared.ids) : ids
        self.extractSnippet = extractSnippet ?? !Defaults[.searchResultExcludeSnippet]
        super.init()
        name = "Search Procedure"
    }
    
    override func main() {
        guard searchText.count > 0 else {return}
        addIndexedSearchResults()
        addTitleSearchResults()
        sort()
    }
    
    private func addIndexedSearchResults() {
        defer { ZimMultiReader.shared.stopIndexSearch() }
        guard !isCancelled else { return }
        ZimMultiReader.shared.startIndexSearch(searchText: searchText, zimFileIDs: ids)
        while let result = ZimMultiReader.shared.getNextIndexSearchResult(extractSnippet: extractSnippet) {
            guard !isCancelled else { return }
            results.insert(result)
        }
    }
    
    private func addTitleSearchResults() {
        guard ids.count > 0 else {return}
        let count = max(5, 30 / ids.count)
        for id in ids {
            guard !isCancelled else {return}
            ZimMultiReader.shared.getTitleSearchResults(searchText: searchText, zimFileID: id, count: count)
                .forEach({ results.insert($0) })
        }
    }
    
    func sort() {
        guard !isCancelled else {return}
        let lowercaseSearchText = searchText.lowercased()
        let levenshtein = Levenshtein()
        sortedResults = results.map { (result) -> (result: SearchResultDeprecated, score: Double) in
            var distance = Double(levenshtein.calculateDistance(a: result.title.lowercased()[...], b: lowercaseSearchText[...]))
            if let probability = result.probability {
                distance = distance * Foundation.log(7.5576 - 6.4524 * probability)
            }
            return (result, distance)
        }.sorted { $0.score < $1.score }.map {$0.result}
    }
}

class Levenshtein {
    private(set) var cache = [Set<String.SubSequence>: Int]()
    
    func calculateDistance(a: String.SubSequence, b: String.SubSequence) -> Int {
        let key = Set([a, b])
        if let distance = cache[key] {
            return distance
        } else {
            let distance: Int = {
                if a.count == 0 || b.count == 0 {
                    return abs(a.count - b.count)
                } else if a.first == b.first {
                    return calculateDistance(a: a[a.index(after: a.startIndex)...], b: b[b.index(after: b.startIndex)...])
                } else {
                    let add = calculateDistance(a: a, b: b[b.index(after: b.startIndex)...])
                    let replace = calculateDistance(a: a[a.index(after: a.startIndex)...], b: b[b.index(after: b.startIndex)...])
                    let delete = calculateDistance(a: a[a.index(after: a.startIndex)...], b: b)
                    return min(add, replace, delete) + 1
                }
            }()
            cache[key] = distance
            return distance
        }
    }
}
