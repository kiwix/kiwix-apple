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
    
    // TODO:
    // ;expires=date-in-UTCString-format: The expiry date of the cookie.
    // ;max-age=max-age-in-seconds: The maximum age of the cookie in seconds (e.g., 60*60*24*365 or 31536000 for a year).
    // - If neither expires nor max-age is specified, it will expire at the end of session.
    
    // Our reference, stable "now" for testing
    // Sun, 02 Aug 2026 08:08:08 GMT
    static let now = Date(timeIntervalSince1970: 1785658088)
    
    @Test(
        "Valid raw input",
        arguments: [
            Cookie(                                  // v--- notice the deliberate space before the ";"
                "_pk_id.3.d4b8=b40a88a69a2c73b3.0.1.0.0.; Expires=Sun, 05 Sep 2027 19:14:17 GMT; Path=/doc.ubuntu-fr.org/;SameSite=Lax",
                [["_pk_id.3.d4b8", "b40a88a69a2c73b3.0.1.0.0."]]
            ),
            Cookie(
                "_pk_ses.3.d4b8=1;Expires=Sat, 08 Aug 2026 19:44:17 GMT;Path=/doc.ubuntu-fr.org/;SameSite=Lax",
                [["_pk_ses.3.d4b8", "1"]]
            ),
            Cookie(
                "theme=dark;;max-age=31536000;Path=/doc.ubuntu-fr.org/",
                [["theme", "dark"]]
            ),
            // expired ones should not be set
            Cookie(
                "myKey=oldValue; max-age=0;",
                []
            ),
            Cookie(
                "myKey=oldValue; expires=Sun, 02 Aug 2026 08:08:07 GMT", // a second ago
                []
            )
        ]
    )
    fileprivate func firstInput(test: Cookie) async throws {
        let mockPersistance = MockPersistance()
        let storage = ZimCookieStore(persistance: mockPersistance)
        let fileID = UUID()
        storage.updateRaw(
            zimFileID: fileID,
            cookie: test.value,
            now: Self.now
        )
        #expect(storage.getAllFor(zimFileID: fileID) == test.expectedResult)
    }
    
    @Test("Set empty value", arguments: ["theme", "theme;", "theme=", "theme=;"])
    fileprivate func setsEmptyValue(input: String) async throws {
        let fileID = UUID()
        let initialState = [fileID: ["theme": ZCookie(value: "dark", expires: nil)]]
        let mockPersistance = MockPersistance()
        mockPersistance.save(initialState)
        let storage = ZimCookieStore(persistance: mockPersistance)
        storage.updateRaw(
            zimFileID: fileID,
            cookie: input,
            now: Date() // doesn't matter in this case
        )
        #expect(mockPersistance.stored == [fileID: ["theme": ZCookie(value: "", expires: nil)]])
    }
    
    // starts with a cookie of red=apple
    @Test("Deleting a specific value", arguments: [
        "red=blue; max-age=0",
        "red=oranage; max-age=-1;",
        "red=yellow; expires=Sun, 02 Aug 2026 08:08:06 GMT"]) // 2 seconds ago
    fileprivate func deletesAValue(input: String) async throws {
        let fileID = UUID()
        let mockPersistance = MockPersistance()
        let storage = ZimCookieStore(persistance: mockPersistance)
        // store some initial value
        storage.updateRaw(zimFileID: fileID, cookie: "red=apple", now: Self.now)
        #expect(mockPersistance.stored == [fileID: ["red": ZCookie(value: "apple", expires: nil)]])
        storage.updateRaw(zimFileID: fileID, cookie: input, now: Self.now)
        // make sure it's deleted
        #expect(mockPersistance.stored == [fileID: [:]])
    }
}

private final class MockPersistance: ZIMCookiePersistance {
    private(set) var stored: [UUID: [String: ZCookie]] = [:]
    
    func load() -> [UUID: [String: ZCookie]] {
        [:]
    }
    func save(_ values: [UUID: [String: ZCookie]]) {
        stored = values
    }
}

extension ZCookie: @retroactive Equatable {
    public static func == (lhs: ZCookie, rhs: ZCookie) -> Bool {
        lhs.value == rhs.value && lhs.expires == rhs.expires
    }
}
