//
//  String+Extension.swift
//  Kiwix
//
//  Created by tvision251 on 11/13/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import Foundation

extension String {

    var localized: String {
        localizedWithFallback()
    }
    
    func localizedWith(comment: String) -> String {
        localizedWithFallback(comment: comment)
    }
    
    func localizedWithFormat(withArgs: CVarArg...) -> String {
        let format = localizedWithFallback()
        switch withArgs.count {
        case 1: return String.localizedStringWithFormat(format, withArgs[0])
        case 2: return String.localizedStringWithFormat(format, withArgs[0], withArgs[1])
        default: return String.localizedStringWithFormat(format, withArgs)
        }
    }

    private func localizedWithFallback(
        bundle: Bundle = DefaultLanguages.currentBundle,
        comment: String = ""
    ) -> String {
        let englishValue: String
        if let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
           let bundle = Bundle(path: path) {
            englishValue = NSLocalizedString(self, bundle: bundle, comment: comment)
            if NSLocale.preferredLanguages.first == "en" {
                return englishValue
            }
        } else {
            englishValue = ""
        }
        return NSLocalizedString(
            self,
            tableName: nil,
            bundle: bundle,
            value: englishValue, // fall back to this, if translation not found
            comment: comment
        )
    }
}
