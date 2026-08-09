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

enum CookieParserResult {
    case delete(key: String)
    case insert(key: String, cookie: ZCookie)
    case invalid
    
    /// Parse a raw JS cookie value, as of document.cookie = "value...."
    /// - Parameter rawValues: JS raw cookie values in a single string
    /// - Returns: a CookieParseResult (either insert key+ZCookie, or delete(by key)
    static func parse(rawValues: String) -> CookieParserResult {
        let (mainKey, dict) = asMainKeyAndDictionary(rawValues)
        guard let mainKey else {
            // it's not a valid cookie if there's no main key
            return .invalid
        }
        let expiryDate = expiryDateFrom(dict)
        let mainValue = dict[mainKey] ?? ""
        return .insert(key: String(mainKey), cookie: ZCookie(value: mainValue, expiry: expiryDate))
    }
    
    /// Parse the raw value of the cookie
    /// - Parameter rawValues: as in JS document.cookie = "value ...."
    /// - Returns: the main key for the cookie (the first in the list) if found, and the remaning key/values in a dict
    static private func asMainKeyAndDictionary(_ rawValues: String) -> (String?, [String: String]) {
        var dict: [String: String] = [:]
        var firstKey: String?
        rawValues.split(separator: ";").enumerated().forEach { i, keyAndValue in
            let keyValue = keyAndValue.split(separator: "=")
            if let key = keyValue.first {
                if i == 0, !key.isEmpty {
                    firstKey = String(key)
                }
                dict[String(key)] = String(keyValue.secondOrEmpty)
            }
        }
        return (firstKey, dict)
    }
    
    static private func expiryDateFrom(_ dict: [String: String]) -> Date? {
        if let expiresString = dict["Expires"], let expiryDate = dateFrom(httpValue: expiresString) {
            return expiryDate
        }
        return nil
    }
    
    static func dateFrom(httpValue: String) -> Date? {
        if #available(iOS 26, macOS 26, *) {
            return try? Date(httpValue, strategy: .http)
        } else {
            return httpDateFormatter.date(from: httpValue)
        }
    }
    
    /// For versions below iOS 26, macOS 26
    private static let httpDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, dd MMM yyyy HH:mm:ss zzz"
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = .gmt
        return formatter
    }()
}

struct ZCookie: Codable {
    let value: String
    let expiry: Date?
}

@MainActor
final class ZimCookieStore {
    
    private let persistance: ZIMCookiePersistance
    private var store: [UUID: [String: ZCookie]]
    
    init(persistance: ZIMCookiePersistance) {
        self.persistance = persistance
        store = persistance.load()
    }
    
    /// Return the whole cookie store for a given ZIM file
    /// - Parameter zimFileID: the associated content
    /// - Returns: in a JS convenient form of nested arrays [[key1, value1], [key2, value2]]
    /// eg: [["theme", "dark"], ["width", "wide"]]
    func getAllFor(zimFileID: UUID) -> [[String]] {
        if let cookies: [String: ZCookie] = store[zimFileID] {
            return cookies.map { (key: String, value: ZCookie) in
                [key, value.value]
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
        switch CookieParserResult.parse(rawValues: newValues) {
        case .invalid:
            return
        case let .delete(key):
            delete(zimFileID: zimFileID, key: key)
        case let .insert(key, cookie):
            update(zimFileID: zimFileID, key: key, cookie: cookie)
        }
    }
    
    func deleteAllFor(zimFileID: UUID) {
        store[zimFileID] = nil
        Log.Cookies.debug("delete all cookies for zimFileID: \(zimFileID)")
        saveStore()
    }
    
    private func update(zimFileID: UUID, key: String, cookie: ZCookie) {
        if store[zimFileID] == nil {
            store[zimFileID] = [key: cookie]
        } else {
            store[zimFileID]?[key] = cookie
        }
        Log.Cookies.debug("update cookie for zimFileID: \(zimFileID), key: \(key) with value: \(cookie.value)")
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
