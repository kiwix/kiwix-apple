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
final class OrderedCache<Key: Hashable, Value> {

    private struct ValueDated<V> {
        let value: V
        let date: Date
    }

    private var dict: [Key: ValueDated<Value>] = [:]

    var count: Int {
        dict.count
    }

    func findBy(key: Key) -> Value? {
        if let dateValue = dict[key] {
            return dateValue.value
        }
        return nil
    }

    func removeAll() {
        dict = [:]
    }

    func removeOlderThan(_ pastDate: Date) {
        dict = dict.filter { (_, value: ValueDated<Value>) in
            value.date >= pastDate
        }
    }

    func removeNotMatchingWith(keys: Set<Key>) -> [Value] {
        let removableKeys = Set(dict.keys).subtracting(keys)
        return removableKeys.compactMap { key in
            dict.removeValue(forKey: key)?.value
        }
    }

    func setValue(_ value: Value, forKey key: Key, dated: Date = Date.now) {
        dict[key] = ValueDated(value: value, date: dated)
    }

    func removeValue(forKey key: Key) {
        dict.removeValue(forKey: key)
        debugPrint("BrowserViewModel cache count: \(dict.count)")
    }
}
