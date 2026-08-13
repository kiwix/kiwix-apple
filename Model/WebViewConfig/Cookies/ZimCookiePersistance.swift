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

struct ZCookiePersisted: Codable {
    let value: String
    let expires: Date
}

@MainActor protocol ZIMCookiePersistance {
    func load() -> [UUID: [String: ZCookiePersisted]]
    func save(_ values: [UUID: [String: ZCookiePersisted]])
}

@MainActor
final class CookiePersistanceInDefaults: ZIMCookiePersistance {
    func load() -> [UUID: [String: ZCookiePersisted]] {
        let storedValues: [String: Data] = Defaults[.cookieStore]
        let decoder = JSONDecoder()
        return storedValues.reduce(into: .init(), { partialResult, zimFileIdCookies in
            if let zimFileId = UUID(uuidString: zimFileIdCookies.key) {
                if let zCookie = try? decoder.decode([String: ZCookiePersisted].self, from: zimFileIdCookies.value) {
                    partialResult.updateValue(zCookie, forKey: zimFileId)
                }
            }
        })
    }
    func save(_ values: [UUID: [String: ZCookiePersisted]]) {
        let encoder = JSONEncoder()
        // map it to a serializable format:
        let storedValues: [String: Data] = values.reduce(.init(), { partialResult, zimFileIDValue in
            let zimFileId: UUID = zimFileIDValue.key
            if let data = try? encoder.encode(zimFileIDValue.value) {
                var newResults = partialResult
                newResults.updateValue(data, forKey: zimFileId.uuidString)
                return newResults
            } else {
                return partialResult
            }
        })
        Defaults[.cookieStore] = storedValues
    }
}
