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
        guard !searchText.isEmpty, let snippetMode = SearchResultSnippetMode(rawValue: self.snippetMode) else { return }
        performSearch()
        extractSnippet(snippetMode)
        sortResults()
    }
    
    /// Extract search result snippet for each search result.
    /// - Parameter mode: describes if and how should the search result be extracted
    private func extractSnippet(_ mode: SearchResultSnippetMode) {
        guard !isCancelled, mode != .disabled else { return }
        let dispatchGroup = DispatchGroup()
        for result in results {
            dispatchGroup.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                defer { dispatchGroup.leave() }
                guard !self.isCancelled else { return }
                
                let url = ZimFileService.shared.getRedirectedURL(url: result.url) ?? result.url
                switch mode {
                case .firstParagraph:
                    guard let parser = try? Parser(url: url) else { return }
                    result.snippet = parser.getFirstParagraph()
                case .firstSentence:
                    guard let parser = try? Parser(url: url) else { return }
                    result.snippet = parser.getFirstSentence(languageCode: nil )
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
    
    /// Sort the search results.
    private func sortResults() {
        guard !isCancelled else { return }
        let searchText = self.searchText.lowercased()
        let levenshtein = Levenshtein()
        
        // calculate score for all search results
        for result in results {
            let distance = levenshtein.calculateDistance(a: result.title.lowercased()[...], b: searchText[...])
            if let probability = result.probability?.doubleValue {
                result.score = NSNumber(floatLiteral: Double(distance) * Foundation.log(7.5576 - 6.4524 * probability))
            } else {
                result.score = NSNumber(integerLiteral: distance)
            }
        }
        
        // sort search results by score
        __results.sort { lhs, rhs in
            guard let lhs = lhs as? SearchResult,
                  let rhs = rhs as? SearchResult,
                  let lhsScore = lhs.score?.doubleValue,
                  let rhsScore = rhs.score?.doubleValue
            else { return .orderedSame }
            
            if lhsScore < rhsScore {
                return .orderedAscending
            } else if lhsScore > rhsScore {
                return .orderedDescending
            } else {
                return .orderedSame
            }
        }
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
