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
                case .matches:
                    guard let html = result.htmlSnippet,
                          let data = html.data(using: .utf8) else { return }
                    result.snippet = try? NSAttributedString(
                        data: data,
                        options: [.documentType: NSAttributedString.DocumentType.html],
                        documentAttributes: nil
                    )
                case .disabled:
                    break
                }
            }
        }
        dispatchGroup.wait()

        // start sorting search results
        guard !isCancelled else { return }
        let searchText = self.searchText.lowercased()

        // calculate score for all results
        for result in results {
            guard !isCancelled else { break }
            let levenshtein = Levenshtein()
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

final class Levenshtein {
    private(set) var cache = [Key: Int]()

    func calculate(_ a: String.SubSequence, _ b: String.SubSequence) -> Int {
        let key = Key(a: a, b: b)
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
        let a: String.SubSequence
        let b: String.SubSequence
    }
}
