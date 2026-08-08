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

@MainActor
final class ZimCookieStore {
    
    private let persistance: ZIMCookiePersistance
    private var store: [UUID: [String: String]]
    
    init(persistance: ZIMCookiePersistance) {
        self.persistance = persistance
        store = persistance.load()
    }
    
    /// Return the whole cookie store for a given ZIM file
    /// - Parameter zimFileID: the associated content
    /// - Returns: in a JS convenient form of nested arrays [[key1, value1], [key2, value2]]
    /// eg: [["theme", "dark"], ["width", "wide"]]
    func getAllFor(zimFileID: UUID) -> [[String]] {
        if let cookies = store[zimFileID] {
            return cookies.map { (key: String, value: String) in
                [key, value]
            }
        } else {
            return []
        }
    }
    
    /// Update the store with raw cookie value
    /// at the moment we are only interested in the key, value
    /// the rest is ignored
    /// - Parameters:
    ///   - zimFileID: the associated content
    ///   - cookie: the raw cookie value as in JS: document.cookie = value
    func updateRaw(zimFileID: UUID, cookie newValues: String) {
        if newValues.isEmpty { return }
        Log.Cookies.debug("\(#function): \(newValues)")
        let keyValues = newValues.split(separator: ";")
        guard let keyAndValue = keyValues.first else { return }
        let keyValue = keyAndValue.split(separator: "=")
        guard let key = keyValue.first else { return }
        let value = keyValue.secondOrEmpty
        update(zimFileID: zimFileID, key: String(key), value: String(value))
    }
    
    func deleteAllFor(zimFileID: UUID) {
        store[zimFileID] = nil
        Log.Cookies.debug("delete all cookies for zimFileID: \(zimFileID)")
        saveStore()
    }
    
    private func update(zimFileID: UUID, key: String, value: String) {
        if store[zimFileID] == nil {
            store[zimFileID] = [key: value]
        } else {
            store[zimFileID]?[key] = value
        }
        Log.Cookies.debug("update cookie for zimFileID: \(zimFileID), key: \(key) with value: \(value)")
        saveStore()
    }
    
    private func delete(zimFileID: UUID, key: String) {
        store[zimFileID]?[key] = nil
        Log.Cookies.debug("delete cookie for zimFileID: \(zimFileID), key: \(key)")
        saveStore()
    }
    
    /// saving the whole store itself on changes
    private func saveStore() {
        persistance.save(store)
    }
}

private extension Array where Element == Substring {
    var secondOrEmpty: Substring {
        guard count > 1 else {
            return ""
        }
        return self[1]
    }
}
