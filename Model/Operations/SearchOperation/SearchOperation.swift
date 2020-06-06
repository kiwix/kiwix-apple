//
//  SearchOperation.swift
//  Kiwix
//
//  Created by Chris Li on 5/9/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import RealmSwift
import Defaults
import SwiftSoup

extension SearchOperation {
    var results: [SearchResult] { get { __results as? [SearchResult] ?? [] } }
    
    open override func main() {
        let mode = Defaults[.searchResultSnippetMode]
        performSearch(mode == .matches)
        if mode != .disabled { extractSnippet(mode) }
        sortResults()
    }
    
    private func extractSnippet(_ mode: SearchResultSnippetMode) {
        let dispatchGroup = DispatchGroup()
        for result in results {
            dispatchGroup.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                defer { dispatchGroup.leave() }
                guard !self.isCancelled else { return }
                
                switch mode {
                case .firstParagraph:
                    guard let parser = try? Parser(zimFileID: result.zimFileID, path: result.url.path) else { return }
                    result.snippet = parser.getFirstParagraph()
                case .firstSentence:
                    guard let parser = try? Parser(zimFileID: result.zimFileID, path: result.url.path) else { return }
                    if #available(iOS 12.0, *) {
                        let database = try? Realm(configuration: Realm.defaultConfig)
                        let zimFile = database?.object(ofType: ZimFile.self, forPrimaryKey: result.zimFileID)
                        result.snippet = parser.getFirstSentence(languageCode: zimFile?.languageCode)
                    } else {
                        result.snippet = nil
                    }
                case .matches:
                    guard let html = result.htmlSnippet else { return }
                    result.snippet = Parser.parseBodyFragment(html)
                default:
                    break
                }
            }
        }
        dispatchGroup.wait()
    }
    
    private func sortResults() {
        guard !isCancelled else {return}
        let searchText = self.searchText.lowercased()
        let levenshtein = Levenshtein()
        __results = results.map { result -> (result: SearchResult, score: Double) in
            var distance = Double(levenshtein.calculateDistance(a: result.title.lowercased()[...], b: searchText[...]))
            if let probability = result.probability?.doubleValue {
                distance = distance * Foundation.log(7.5576 - 6.4524 * probability)
            }
            return (result, distance)
        }.sorted { $0.score < $1.score }.map { $0.result }
    }
}

private class Levenshtein {
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
