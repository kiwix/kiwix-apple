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

/// Helper to collect all language codes with counts,
/// some of them are coma separated entries in the DB, such as "eng,spa,por"
final class LanguageCollector {

    private var items: [String: Int] = [:]

    func addLanguages(codes: String, count: Int) {
        Set(codes.split(separator: ",")).forEach { code in
            addLanguage(code: String(code), count: count)
        }
    }

    func languages() -> [Language] {
        items.compactMap { (code: String, count: Int) -> Language? in
            Language(code: code, count: count)
        }.sorted()
    }

    private func addLanguage(code: String, count: Int) {
        if let previousCount = items[code] {
            items[code] = previousCount + count
        } else {
            items[code] = count
        }
    }

}
