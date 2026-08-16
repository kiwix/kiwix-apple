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

@MainActor
struct ZimCookieStoreTest {

    struct CookiesT {
        let value: String
        let expectedResult: String
        init(_ value: String, _ expectedResult: String) {
            self.value = value
            self.expectedResult = expectedResult
        }
    }

    // swiftlint:disable line_length
    @Test(
        "Valid JSON input",
        arguments: [
            """
[["theme",{"value":"dark","expiryDate":"2027-08-15T18:18:42.026Z"}],["_pk_id.3.d4b8",{"value":"7b0a9ee549f25c24.0.1.0.0.","expiryDate":"2027-09-12T18:18:38.000Z"}],["_pk_ses.3.d4b8",{"value":"1","expiryDate":"2026-08-15T18:48:38.000Z"}],["width",{"value":"narrow","expiryDate":"2027-08-15T18:18:40.797Z"}]]
""",
            """
[["myKey",{"value":"O'Reilly","expiryDate":"2026-08-17T04:45:16.000Z"}]]
"""
        ]
    )
    func validInput(json: String) async throws {
        let mockPersistence = MockPersistence()
        let storage = ZimCookieStore(persistence: mockPersistence)
        let fileID = UUID()
        storage.save(zimFileID: fileID, cookies: json)
        #expect(storage.getAllFor(zimFileID: fileID) == json)
        #expect(mockPersistence.load() == [fileID: json])
    }
    // swiftlint:enable line_length

    @Test("empty store value deletes the whole store for the given ZIM file", arguments: ["", "[]"])
    func emptyStoreDeletes(json: String) async throws {
        let mockPersistance = MockPersistence()
        let fileID = UUID(uuidString: "C6534BDD-54C0-4A9D-9031-F9222A6520CB")!
        let otherFileID = UUID(uuidString: "B488A934-7A85-47ED-974F-3AEC752E53BC")!
        let mockJsonValue = "[other mock json value]"

        mockPersistance.save([otherFileID: mockJsonValue,
                                   fileID: "[the current file json value]"])

        #expect(!mockPersistance.load().isEmpty)
        let store = ZimCookieStore(persistence: mockPersistance)
        store.save(zimFileID: fileID, cookies: json)
        #expect(mockPersistance.load()[fileID] == nil)
        #expect(mockPersistance.load()[otherFileID] == mockJsonValue)
    }
}

private final class MockPersistence: ZIMCookiePersistence {
    private var stored: [UUID: String] = [:]
    func load() -> [UUID: String] {
        stored
    }
    func save(_ values: [UUID: String]) {
        stored = values
    }
}
