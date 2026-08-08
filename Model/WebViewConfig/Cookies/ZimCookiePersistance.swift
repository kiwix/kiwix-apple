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

@MainActor protocol ZIMCookiePersistance {
    func load() -> [UUID: [String: String]]
    func save(_ values: [UUID: [String: String]])
}

@MainActor
final class CookiePersistanceInDefaults: ZIMCookiePersistance {
    func load() -> [UUID: [String: String]] {
        let storedValues: [String: [String: String]] = Defaults[.cookieStore]
        return storedValues.reduce(into: .init(), { partialResult, zimFileIdCookies in
            if let zimFileId = UUID(uuidString: zimFileIdCookies.key) {
                let cookies = zimFileIdCookies.value
                partialResult.updateValue(cookies, forKey: zimFileId)
            }
        })
    }
    func save(_ values: [UUID: [String: String]]) {
        // map it to a serializable format:
        let storedValues: [String: [String: String]] = values.reduce(.init(), { partialResult, zimFileIDValue in
            let zimFileId: UUID = zimFileIDValue.key
            let cookies: [String: String] = zimFileIDValue.value
            var newResults = partialResult
            newResults.updateValue(cookies, forKey: zimFileId.uuidString)
            return newResults
        })
        Defaults[.cookieStore] = storedValues
    }
}
