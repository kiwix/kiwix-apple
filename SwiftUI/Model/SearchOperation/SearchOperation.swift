//
//  SearchOperation.swift
//  Kiwix
//
//  Created by Chris Li on 5/9/20.
//  Copyright © 2020-2022 Chris Li. All rights reserved.
//

extension SearchOperation {
    var results: [SearchResult] { get { __results.array as? [SearchResult] ?? [] } }

    open override func main() {
        // perform index and title search
        guard !searchText.isEmpty else { return }
        performSearch()
        
        // parse and extract search result snippet
        #if os(iOS)
        guard !isCancelled else { return }
        let snippetMode = SearchResultSnippetMode(rawValue: self.snippetMode) ?? .disabled
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
        #endif
        
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
        
        guard !isCancelled else { return }
        __results.sort { lhs, rhs in
            guard let lhs = (lhs as? SearchResult)?.score?.doubleValue,
                  let rhs = (rhs as? SearchResult)?.score?.doubleValue else { return .orderedSame }
            if lhs < rhs {
                return .orderedAscending
            } else if lhs > rhs {
                return .orderedDescending
            } else {
                return .orderedSame
            }
        }
    }
}

private class Levenshtein {
    private(set) var cache = [Set<String>: Int]()
    
    func calculate(_ a: String.SubSequence, _ b: String.SubSequence) -> Int {
        let key = Set([String(a), String(b)])
        if let distance = cache[key] {
            return distance
        } else {
            let distance: Int = {
                if a.count == 0 || b.count == 0 {
                    return abs(a.count - b.count)
                } else if a.first == b.first {
                    return calculate(a[a.index(after: a.startIndex)...], b[b.index(after: b.startIndex)...])
                } else {
                    let add = calculate(a, b[b.index(after: b.startIndex)...])
                    let replace = calculate(a[a.index(after: a.startIndex)...], b[b.index(after: b.startIndex)...])
                    let delete = calculate(a[a.index(after: a.startIndex)...], b)
                    return min(add, replace, delete) + 1
                }
            }()
            cache[key] = distance
            return distance
        }
    }
}
