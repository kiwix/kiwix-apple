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

    func removingPrefix(_ value: String) -> String {
        guard hasPrefix(value) else { return self }
        return String(dropFirst(value.count))
    }
    
    func removingSuffix(_ value: String) -> String {
        guard hasSuffix(value) else { return self }
        return String(dropLast(value.count))
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
