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
        return !languages.intersection(langCodes).isEmpty
    }

    static func save(_ dictionary: [Category: Set<String>]) {
        Defaults[.categoriesToLanguages] = dictionary
    }
}
