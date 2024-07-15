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

/// @see: https://en.wikipedia.org/wiki/Wagner–Fischer_algorithm
enum WagnerFischer {

    // swiflint:disable:next identifier_name
    static func distance(_ a: String.SubSequence, _ b: String.SubSequence) -> Int {
        let empty = [Int](repeating: 0, count: b.count)
        var last = [Int](0...b.count)

        for (i, char1) in a.enumerated() {
            var cur = [i + 1] + empty
            for (j, char2) in b.enumerated() {
                let currentDistance: Int
                if char1 == char2 {
                    currentDistance = last[j]
                } else {
                    currentDistance = min(last[j], last[j + 1], cur[j]) + 1
                }
                cur[j + 1] = currentDistance
            }
            last = cur
        }
        return last.last!
    }
    // swiflint:enable identifier_name
}
