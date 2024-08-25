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

import XCTest
@testable import Kiwix

final class MigrationServiceTests: XCTestCase {

    func test_no_migrations() {
        let service = MigrationService(migrations: [])
        XCTAssertTrue(service.migrateAll(using: MockUserDefaults()))
    }

    func test_one_successful_migration() {
        var migrationCount = 0
        let successMigration = Migration(userDefaultsKey: "success") {
            migrationCount += 1
            return true
        }
        let service = MigrationService(migrations: [successMigration])
        let mockUserDefaults = MockUserDefaults()
        XCTAssertTrue(service.migrateAll(using: mockUserDefaults))
        XCTAssertEqual(migrationCount, 1)
        // doing it again should also succeed
        XCTAssertTrue(service.migrateAll(using: mockUserDefaults))
        // but should be processed only one time
        XCTAssertEqual(migrationCount, 1)
    }

    func test_already_migrated() {
        var migrationCount = 0
        let testKey = "already_processed"
        let migration = Migration(userDefaultsKey: testKey, migration: {
            migrationCount += 1
            return true
        })
        let service = MigrationService(migrations: [migration])
        let savedAsDone = [testKey: true]
        XCTAssertTrue(service.migrateAll(using: MockUserDefaults(values: savedAsDone)))
        XCTAssertEqual(migrationCount, 0)
    }

    func test_one_failing_migration() {
        let failingMigration = Migration(userDefaultsKey: "failing") {
            return false
        }
        let service = MigrationService(migrations: [failingMigration])
        XCTAssertFalse(service.migrateAll(using: MockUserDefaults()))
    }

    func test_a_mix_of_successful_and_failing_migrations() {
        var failingMigrationCount = 0
        let failingMigration = Migration(userDefaultsKey: "failing") {
            failingMigrationCount += 1
            return false
        }
        var successMigrationCount = 0
        let successMigration = Migration(userDefaultsKey: "success") {
            successMigrationCount += 1
            return true
        }
        let service = MigrationService(migrations: [failingMigration, successMigration])
        let mockUserDefaults = MockUserDefaults()
        XCTAssertFalse(service.migrateAll(using: mockUserDefaults))
        XCTAssertEqual(failingMigrationCount, 1)
        XCTAssertEqual(successMigrationCount, 1)
        // by running it again, it should re-process only the failed one
        XCTAssertFalse(service.migrateAll(using: mockUserDefaults))
        XCTAssertEqual(failingMigrationCount, 2)
        XCTAssertEqual(successMigrationCount, 1)
    }

}

private final class MockUserDefaults: UserDefaulting {
    private var values: [String: Bool]

    init(values: [String : Bool] = [:]) {
        self.values = values
    }

    func bool(forKey defaultName: String) -> Bool {
        values[defaultName] ?? false
    }
    
    func setValue(_ value: Any?, forKey key: String) {
        values[key] = (value as? Bool) ?? false
    }
}
