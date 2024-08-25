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

import Foundation

protocol UserDefaulting {
    func bool(forKey defaultName: String) -> Bool
    func setValue(_ value: Any?, forKey key: String)
}
extension UserDefaults: UserDefaulting {}

struct Migration {
    let userDefaultsKey: String
    let migration: () -> Bool

    func migrate(_ userDefaults: UserDefaulting) -> Bool {
        guard userDefaults.bool(forKey: userDefaultsKey) != true else {
            // migration was done earlier
            return true
        }
        let result: Bool = migration()
        userDefaults.setValue(result, forKey: userDefaultsKey)
        return result
    }
}

struct MigrationService {
    let migrations: [Migration]

    func migrateAll(using userDefaults: UserDefaulting = UserDefaults.standard) -> Bool {
        var allSucceeded = true
        for migration in migrations {
            if migration.migrate(userDefaults) == false {
                allSucceeded = false
            }
        }
        return allSucceeded
    }
}
