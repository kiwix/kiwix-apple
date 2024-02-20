//
//  CategoriesToLanguage.swift
//  Kiwix
//

import Foundation
import Defaults

struct CategoriesToLanguages {

    private let dictionary: [Category: Set<String>] = Defaults[.categoriesToLanguages]

    func has(category: Category, inLanguages langCodes: Set<String>) -> Bool {
        guard !langCodes.isEmpty else {
            return true // no languages provided, do not filter
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
