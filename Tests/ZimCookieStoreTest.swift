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

import Testing
@testable import Kiwix

private struct Cookie {
    init(_ value: String, _ expectedResult: [[String]]) {
        self.value = value
        self.expectedResult = expectedResult
    }
    let value: String
    let expectedResult: [[String]]
}

@MainActor
struct ZimCookieStoreTest {
    
    @Test(
        "Valid raw input",
        arguments: [
            Cookie(
                "_pk_id.3.d4b8=b40a88a69a2c73b3.0.1.0.0.;Expires=Sun, 05 Sep 2027 19:14:17 GMT;Path=/doc.ubuntu-fr.org/;SameSite=Lax",
                [["_pk_id.3.d4b8", "b40a88a69a2c73b3.0.1.0.0."]]
            ),
            Cookie(
                "_pk_ses.3.d4b8=1;Expires=Sat, 08 Aug 2026 19:44:17 GMT;Path=/doc.ubuntu-fr.org/;SameSite=Lax",
                [["_pk_ses.3.d4b8", "1"]]
            ),
            Cookie(
                "theme=dark;;max-age=31536000;Path=/doc.ubuntu-fr.org/",
                [["theme", "dark"]]
            )
        ]
    )
    fileprivate func firstInput(test: Cookie) async throws {
        let mockPersistance = MockPersistance()
        let storage = ZimCookieStore(persistance: mockPersistance)
        let fileID = UUID()
        storage.updateRaw(
            zimFileID: fileID,
            cookie: test.value
        )
        #expect(storage.getAllFor(zimFileID: fileID) == test.expectedResult)
    }
    
    @Test("Set empty value", arguments: ["theme", "theme;", "theme=", "theme=;"])
    fileprivate func setsEmptyValue(input: String) async throws {
        let fileID = UUID()
        let initialState = [fileID: ["theme": "dark"]]
        let mockPersistance = MockPersistance()
        mockPersistance.save(initialState)
        let storage = ZimCookieStore(persistance: mockPersistance)
        storage.updateRaw(
            zimFileID: fileID,
            cookie: input
        )
        #expect(mockPersistance.stored == [fileID: ["theme": ""]])
    }
}

private final class MockPersistance: ZIMCookiePersistance {
    private(set) var stored: [UUID: [String: String]] = [:]
    
    func load() -> [UUID: [String: String]] {
        [:]
    }
    func save(_ values: [UUID: [String: String]]) {
        stored = values
    }
}
