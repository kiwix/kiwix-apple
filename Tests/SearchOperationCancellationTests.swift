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
import XCTest
@testable import Kiwix

final class SearchOperationCancellationTests: XCTestCase {
    func testCancellationAfterNativeSearchSkipsSnippetParsing() throws {
        let oldMode = Defaults[.searchResultSnippetMode]
        Defaults[.searchResultSnippetMode] = .matches
        defer { Defaults[.searchResultSnippetMode] = oldMode }
        let operation = makeOperation()
        let result = try makeResult(path: "one")
        operation.seededResults = [result]
        operation.cancelAfterSearch = true

        operation.main()

        XCTAssertTrue(operation.isCancelled)
        XCTAssertNil(result.snippet)
        XCTAssertNil(result.score)
    }

    func testCancellationDuringParsingSkipsRemainingSnippets() throws {
        let oldMode = Defaults[.searchResultSnippetMode]
        Defaults[.searchResultSnippetMode] = .matches
        defer { Defaults[.searchResultSnippetMode] = oldMode }
        let operation = makeOperation()
        let results = try ["one", "two", "three"].map { try makeResult(path: $0) }
        for result in results {
            result.onParsed = { [weak operation] in operation?.cancel() }
        }
        operation.seededResults = results

        operation.main()

        XCTAssertTrue(operation.isCancelled)
        XCTAssertEqual(results.filter { $0.snippet != nil }.count, 1)
    }

    func testUncancelledSearchParsesAndScoresResults() throws {
        let oldMode = Defaults[.searchResultSnippetMode]
        Defaults[.searchResultSnippetMode] = .matches
        defer { Defaults[.searchResultSnippetMode] = oldMode }
        let operation = makeOperation()
        let result = try makeResult(path: "one")
        operation.seededResults = [result]

        operation.main()

        XCTAssertFalse(operation.isCancelled)
        XCTAssertEqual(result.snippet?.string, "match")
        XCTAssertNotNil(result.score)
    }

    private func makeOperation() -> StubSearchOperation {
        StubSearchOperation(searchText: "match", zimFileIDs: [], withSpellingCacheDir: nil)
    }

    private func makeResult(path: String) throws -> ParsingSearchResult {
        let result = try XCTUnwrap(ParsingSearchResult(zimFileID: UUID(), path: path, title: "match"))
        result.htmlSnippet = "<b>match</b>"
        return result
    }
}

private final class StubSearchOperation: SearchOperation, @unchecked Sendable {
    var seededResults = [SearchResult]()
    var cancelAfterSearch = false

    override func performSearch() {
        __results.addObjects(from: seededResults)
        if cancelAfterSearch {
            cancel()
        }
    }
}

private final class ParsingSearchResult: SearchResult {
    var onParsed: (() -> Void)?

    override var snippet: NSAttributedString? {
        get { super.snippet }
        set {
            super.snippet = newValue
            if newValue != nil {
                onParsed?()
            }
        }
    }
}
