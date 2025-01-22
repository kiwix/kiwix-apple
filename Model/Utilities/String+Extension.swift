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

extension String {

    var localized: String {
        localizedWithFallback()
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
        bundle: Bundle = Bundle.main,
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

    func removingPrefix(_ value: String) -> String {
        guard hasPrefix(value) else { return self }
        return String(dropFirst(value.count))
    }

    func replacingRegex(
        matching pattern: String,
        findingOptions: NSRegularExpression.Options = .caseInsensitive,
        replacingOptions: NSRegularExpression.MatchingOptions = [],
        with template: String
    ) throws -> String {
        let regex = try NSRegularExpression(pattern: pattern, options: findingOptions)
        let range = NSRange(startIndex..., in: self)
        return regex.stringByReplacingMatches(in: self, options: replacingOptions, range: range, withTemplate: template)
    }
}
