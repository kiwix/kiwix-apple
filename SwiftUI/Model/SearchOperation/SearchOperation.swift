// This file is part of Kiwix for iOS & macOS.
//
// Kiwix is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// any later version.
//
// Kiwix is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Kiwix; If not, see https://www.gnu.org/licenses/.

import Defaults

extension SearchOperation {
    private var searchResults: [SearchResult] { __results.array as? [SearchResult] ?? [] }
    private var corrections: [String] { __corrections.array as? [String] ?? [] }
    var searchResultItems: SearchResultItems {
        if !corrections.isEmpty {
            .suggestions(corrections)
        } else {
            .results(searchResults)
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    open override func main() {
        __results.removeAllObjects()
        __corrections.removeAllObjects()
        // perform index and title search
        guard !searchText.isEmpty else { return }
        performSearch()

        // reduce to unique results by URL
        let uniqueDict = Dictionary(grouping: searchResults, by: { $0.url })
        let values = uniqueDict.compactMapValues { $0.first }.values
        __results = NSMutableOrderedSet(array: Array(values) )

        // parse and extract search result snippet
        if case .matches = Defaults[.searchResultSnippetMode] {
            for result in searchResults {
                guard let html = result.htmlSnippet,
                      let data = html.data(using: .utf8) else { continue }
                result.snippet = try? NSAttributedString(
                    data: data,
                    options: [.documentType: NSAttributedString.DocumentType.html,
                              .characterEncoding: String.Encoding.utf8.rawValue],
                    documentAttributes: nil
                )
            }
        }

        // start sorting search results
        let searchText = searchText.lowercased()

        // swiftlint:disable compiler_protocol_init
        // calculate score for all results
        for result in searchResults {
            guard !isCancelled else { return }
            let distance = WagnerFischer.distance(result.title.lowercased()[...], searchText[...])
            if let probability = result.probability?.doubleValue {
                result.score = NSNumber(floatLiteral: Double(distance) * Foundation.log(7.5576 - 6.4524 * probability))
            } else {
                result.score = NSNumber(integerLiteral: distance)
            }
        }
        // swiftlint:enable compiler_protocol_init

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

        performSuggestions()
    }
    
    private func performSuggestions() {
        guard !isCancelled,
              !zimFileIDs.isEmpty,
              searchText.count > 2,
              searchResults.isEmpty,
              spellCacheDir != nil else {
            __corrections = []
            return
        }
        Log.LibraryOperations.debug("perfoming search suggestsion")
        let count: Int = __corrections.count
        Log.LibraryOperations.debug("found search suggestsion: \(count, privacy: .public)")
    }
}
