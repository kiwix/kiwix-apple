/*
 * This file is part of Kiwix for iOS & macOS.
 *
 * Kiwix is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * any later version.
 *
 * Kiwix is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Kiwix; If not, see https://www.gnu.org/licenses/.
*/

//
//  CategoriesToLanguage.swift
//  Kiwix
//

import Foundation
import Defaults

struct CategoriesToLanguages {
    
    private let dictionary: [Category: Set<String>] = Defaults[.categoriesToLanguages]
    
    func has(category: Category, inLanguages langCodes: Set<String>) -> Bool {
        guard !langCodes.isEmpty, !dictionary.isEmpty else {
            return true // no languages or category filters provided, do not filter
        }
        guard let languages = dictionary[category] else {
            return false
        }
        return !languages.isDisjoint(with: langCodes)
    }
    
    static func save(_ dictionary: [Category: Set<String>]) {
        Defaults[.categoriesToLanguages] = dictionary
    }
    
    static func allCategories() -> [Category] {
        let categoriesToLanguages = CategoriesToLanguages()
        let contentLanguages = Defaults[.libraryLanguageCodes]
        return Category.allCases.filter { (category: Category) in
            categoriesToLanguages.has(category: category, inLanguages: contentLanguages)
        }
    }
}
