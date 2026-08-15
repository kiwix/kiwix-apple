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
import Foundation

@MainActor protocol ZIMCookiePersistence {
    func load() -> [UUID: String]
    func save(_ values: [UUID: String])
}

@MainActor
final class CookiePersistenceInDefaults: ZIMCookiePersistence {
    func load() -> [UUID: String] {
        let storedValues: [String: String] = Defaults[.cookieStore]
        return storedValues.reduce(into: .init(), { partialResult, zimFileIdCookies in
            if let zimFileId = UUID(uuidString: zimFileIdCookies.key) {
                partialResult.updateValue(zimFileIdCookies.value, forKey: zimFileId)
            }
        })
    }
    func save(_ values: [UUID: String]) {
        let storedValues: [String: String] = values.reduce(into: [:]) { nextPartialResult, zimFileIDValue in
            nextPartialResult.updateValue(zimFileIDValue.value, forKey: zimFileIDValue.key.uuidString)
        }
        Defaults[.cookieStore] = storedValues
    }
}
