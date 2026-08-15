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

@MainActor
final class ZimCookieStore {
    
    private let persistence: ZIMCookiePersistence
    private var store: [UUID: String]
    
    init(persistence: ZIMCookiePersistence) {
        self.persistence = persistence
        store = persistence.load()
    }
    
    /// Return the whole cookie store for a given ZIM file
    /// it's a JSON encoded string
    func getAllFor(zimFileID: UUID) -> String? {
        store[zimFileID]
    }
    
    /// - Parameters:
    ///   - zimFileID: the associated content
    ///   - cookie: the JSON encoded cookie values
    func save(zimFileID: UUID, cookies jsonValues: String) {
        Log.Cookies.debug("\(#function): \(jsonValues)")
        guard !jsonValues.isEmpty else {
            deleteAllFor(zimFileID: zimFileID)
            return
        }
        store[zimFileID] = jsonValues
        saveStore()
    }
    
    func deleteAllFor(zimFileID: UUID) {
        store[zimFileID] = nil
        Log.Cookies.debug("delete all cookies for zimFileID: \(zimFileID)")
        saveStore()
    }
    
    /// saving the whole store itself on changes
    private func saveStore() {
        persistence.save(store)
    }
}
