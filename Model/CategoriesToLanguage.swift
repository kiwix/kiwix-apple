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

protocol CategoriesProtocol {
    func has(category: Category, inLanguages langCodes: Set<String>) -> Bool
    func save(_ dictionary: [Category: Set<String>])
    func allCategories() -> [Category]
}

struct CategoriesToLanguages: CategoriesProtocol {
    
    private let defaults: Defaulting
    private let dictionary: [Category: Set<String>]
    
    init(withDefaults defaults: Defaulting = UDefaults()) {
        self.defaults = defaults
        self.dictionary = defaults[.categoriesToLanguages]
    }

    func has(category: Category, inLanguages langCodes: Set<String>) -> Bool {
        guard !langCodes.isEmpty, !dictionary.isEmpty else {
            return true // no languages or category filters provided, do not filter
        }
        guard let languages = dictionary[category] else {
            return false
        }
        return !languages.isDisjoint(with: langCodes)
    }

    func save(_ dictionary: [Category: Set<String>]) {
        defaults[.categoriesToLanguages] = dictionary
    }

    func allCategories() -> [Category] {
        let categoriesToLanguages = CategoriesToLanguages()
        let contentLanguages = defaults[.libraryLanguageCodes]
        return Category.allCases.filter { (category: Category) in
            categoriesToLanguages.has(category: category, inLanguages: contentLanguages)
        }
    }
}
