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

enum CSSUnit: String {
    case em
}

enum Javascript {
    static func webkitPadding(size: UInt8, unit: CSSUnit = .em) -> String {
        let paddingTemplate = "document.getElementsByTagName('body')[0].style.webkit%@='%d%@'"
        return ["PaddingStart", "PaddingEnd", "PaddingBefore", "PaddingAfter"].map { property in
            String(format: paddingTemplate, property, size, unit.rawValue)
        }.joined(separator: "; ")
    }
}
