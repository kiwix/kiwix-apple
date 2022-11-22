//
//  SearchOperation.swift
//  Kiwix
//
//  Created by Chris Li on 5/9/20.
//  Copyright © 2020-2022 Chris Li. All rights reserved.
//

import Defaults

extension SearchOperation {
    var results: [SearchResult] { get { __results.array as? [SearchResult] ?? [] } }

    open override func main() {
        // perform index and title search
        guard !searchText.isEmpty else { return }
        performSearch()
        
        // parse and extract search result snippet
        guard !isCancelled else { return }
        let snippetMode = Defaults[.searchResultSnippetMode]
        let dispatchGroup = DispatchGroup()
        for result in results {
            dispatchGroup.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                defer { dispatchGroup.leave() }
                guard !self.isCancelled else { return }
                
                switch snippetMode {
                case .firstParagraph:
                    guard let parser = try? HTMLParser(url: result.url) else { return }
                    result.snippet = parser.getFirstParagraph()
                case .firstSentence:
                    guard let parser = try? HTMLParser(url: result.url) else { return }
                    result.snippet = parser.getFirstSentence(languageCode: nil)
                case .matches:
                    guard let html = result.htmlSnippet else { return }
                    result.snippet = HTMLParser.parseBodyFragment(html)
                case .disabled:
                    break
                }
            }
        }
        dispatchGroup.wait()
        
        // start sorting search results
        guard !isCancelled else { return }
        let searchText = self.searchText.lowercased()
        let levenshtein = Levenshtein()
        
        // calculate score for all results
        for result in results {
            guard !isCancelled else { break }
            let distance = levenshtein.calculate(result.title.lowercased()[...], searchText[...])
            if let probability = result.probability?.doubleValue {
                result.score = NSNumber(floatLiteral: Double(distance) * Foundation.log(7.5576 - 6.4524 * probability))
            } else {
                result.score = NSNumber(integerLiteral: distance)
            }
        }
        
        // sort the results
        guard !isCancelled else { return }
        __results.sort { lhs, rhs in
            guard let lhs = lhs as? SearchResult,
                  let rhs = rhs as? SearchResult,
                  let lhsScore = lhs.score?.doubleValue,
                  let rhsScore = rhs.score?.doubleValue else { return .orderedSame }
            if lhsScore != rhsScore {
                return lhsScore < rhsScore ? .orderedAscending : .orderedDescending
            } else if let lhsSnippet = lhs.snippet, let rhsSnippet = rhs.snippet {
                return lhsSnippet.length > rhsSnippet.length ? .orderedAscending : .orderedDescending
            } else {
                return .orderedSame
            }
        }
    }
}

private class Levenshtein {
    private(set) var cache = [Key: Int]()
    
    func calculate(_ a: String.SubSequence, _ b: String.SubSequence) -> Int {
        let key = Key(a: String(a), b: String(b))
        if let distance = cache[key] {
            return distance
        } else {
            let distance: Int = {
                if a.count == 0 || b.count == 0 {
                    return abs(a.count - b.count)
                } else if a.last == b.last {
                    return calculate(a[..<a.index(before: a.endIndex)], b[..<b.index(before: b.endIndex)])
                } else {
                    let add = calculate(a, b[..<b.index(before: b.endIndex)])
                    let replace = calculate(a[..<a.index(before: a.endIndex)], b[..<b.index(before: b.endIndex)])
                    let delete = calculate(a[..<a.index(before: a.endIndex)], b)
                    return min(add, replace, delete) + 1
                }
            }()
            cache[key] = distance
            return distance
        }
    }
    
    struct Key: Hashable {
        let a: String
        let b: String
    }
}
