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

private struct CookieT {
    init(_ value: String, _ expectedResult: [[String]]) {
        self.value = value
        self.expectedResult = expectedResult
    }
    let value: String
    let expectedResult: [[String]]
}
// swiftlint:disable line_length
@MainActor
struct ZimCookieStoreTest {
    
    // Our reference, stable "now" for testing
    // Sun, 02 Aug 2026 08:08:08 GMT
    static let now = Date(timeIntervalSince1970: 1785658088)
    
    @Test(
        "Valid raw input",
        arguments: [
            CookieT(                                  // v--- notice the deliberate space before the ";"
                "_pk_id.3.d4b8=b40a88a69a2c73b3.0.1.0.0.; Expires=Sun, 05 Sep 2027 19:14:17 GMT; Path=/doc.ubuntu-fr.org/;SameSite=Lax",
                [["_pk_id.3.d4b8", "b40a88a69a2c73b3.0.1.0.0."]]
            ),
            CookieT(
                "_pk_ses.3.d4b8=1;Expires=Sat, 08 Aug 2026 19:44:17 GMT;Path=/doc.ubuntu-fr.org/;SameSite=Lax",
                [["_pk_ses.3.d4b8", "1"]]
            ),
            CookieT(
                "theme=dark;;max-age=31536000;Path=/doc.ubuntu-fr.org/",
                [["theme", "dark"]]
            ),
            // expired ones should not be set
            CookieT(
                "myKey=oldValue; max-age=0;",
                []
            ),
            CookieT(
                "myKey=oldValue; expires=Sun, 02 Aug 2026 08:08:07 GMT", // a second ago
                []
            )
        ]
    )
    fileprivate func firstInput(test: CookieT) async throws {
        let mockPersistance = MockPersistence()
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
        let mockPersistance = MockPersistence()
        let storage = ZimCookieStore(persistance: mockPersistance)
        // set an initial value, date doesn't matter
        storage.updateRaw(zimFileID: fileID, cookie: "theme=dark;", now: Self.now)
        storage.updateRaw(
            zimFileID: fileID,
            cookie: input,
            now: Self.now // date doesn't matter in this case
        )
        #expect(storage.getAllFor(zimFileID: fileID, now: Self.now) == [["theme", ""]])
    }
    
    // starts with a cookie of red=apple
    @Test("Deleting a specific value", arguments: [
        "red=blue; max-age=0",
        "red=oranage; max-age=-1;",
        "red=yellow; expires=Sun, 02 Aug 2026 08:08:06 GMT"]) // 2 seconds ago
    fileprivate func deletesAValue(input: String) async throws {
        let fileID = UUID()
        let mockPersistance = MockPersistence()
        let storage = ZimCookieStore(persistance: mockPersistance)
        // store some initial value
        storage.updateRaw(zimFileID: fileID, cookie: "red=apple", now: Self.now)
        #expect(storage.getAllFor(zimFileID: fileID, now: Self.now) == [["red", "apple"]])
        storage.updateRaw(zimFileID: fileID, cookie: input, now: Self.now)
        // make sure it's not stored in memory
        #expect(storage.getAllFor(zimFileID: fileID, now: Self.now).isEmpty)
        // make sure it's not persisted
        #expect(mockPersistance.stored == [fileID: [:]])
    }
    
    @Test("Session only cookies, should not be persisted", arguments: [
        "kiwix_cookie=session only"
    ])
    fileprivate func sessionOnly(input: String) async throws {
        let fileID = UUID()
        let mockPersistance = MockPersistence()
        let storage = ZimCookieStore(persistance: mockPersistance)
        storage.updateRaw(zimFileID: fileID, cookie: input, now: Self.now)
        let inMemory: [[String]] = storage.getAllFor(zimFileID: fileID)
        #expect(inMemory == [["kiwix_cookie", "session only"]])
        // make sure it's not stored
        #expect(mockPersistance.stored == [fileID: [:]])
    }
}
// swiftlint:enable line_length

private final class MockPersistence: ZIMCookiePersistence {
    private(set) var stored: [UUID: [String: ZCookiePersisted]] = [:]
    
    func load() -> [UUID: [String: ZCookiePersisted]] {
        [:]
    }
    func save(_ values: [UUID: [String: ZCookiePersisted]]) {
        stored = values
    }
}

extension ZCookiePersisted: @retroactive Equatable {
    public static func == (lhs: ZCookiePersisted, rhs: ZCookiePersisted) -> Bool {
        lhs.value == rhs.value && lhs.expires == rhs.expires
    }
}
