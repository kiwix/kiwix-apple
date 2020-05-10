//
//  SearchOperation.swift
//  Kiwix
//
//  Created by Chris Li on 5/9/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

#if os(OSX)
    import Cocoa
#elseif os(iOS)
    import UIKit
#endif
import SwiftSoup
import SwiftyUserDefaults

extension SearchOperation {
    var results: [SearchResult] { get { __results as? [SearchResult] ?? [] } }
    static private let boldFont = NSUIFont.boldSystemFont(ofSize: 12.0)
    
    open override func main() {
        let shouldExtractSnippet = !Defaults[.searchResultExcludeSnippet]
        let mode = SnippetExtractionMode(rawValue: Defaults[.searchResultSnippetExtractionMode])
            ?? SnippetExtractionMode.matches
        
        __results = getSearchResults(shouldExtractSnippet && mode == .matches)
        if shouldExtractSnippet { extractSnippet(mode) }
        sortResults()
    }
    
    private func extractSnippet(_ mode: SnippetExtractionMode) {
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
                case .matches:
                    result.snippet = self.getMatchesSnippet(html: result.htmlSnippet)
                }
            }
        }
        dispatchGroup.wait()
    }
    
    private func getMatchesSnippet(html: String?) -> NSAttributedString? {
        guard let html = html, let body = try? SwiftSoup.parseBodyFragment(html).body() else { return nil }
        let snippet = NSMutableAttributedString()
        for node in body.getChildNodes() {
            if let element = node as? Element, let text = try? element.text(), element.tagName() == "b" {
                snippet.append(NSAttributedString(string: text, attributes: [.font: SearchOperation.boldFont]))
            } else if let text = try? node.outerHtml() {
                snippet.append(NSAttributedString(string: text.trimmingCharacters(in: .newlines)))
            }
        }
        return snippet
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
    
    enum SnippetExtractionMode: String {
        case firstParagraph, matches
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
