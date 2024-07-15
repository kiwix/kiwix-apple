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

    static func distance(_ valueA: String.SubSequence, _ valueB: String.SubSequence) -> Int {
        let empty = [Int](repeating: 0, count: valueB.count)
        var last = [Int](0...valueB.count)

        for (indexA, charA) in valueA.enumerated() {
            var current = [indexA + 1] + empty
            for (indexB, charB) in valueB.enumerated() {
                let currentDistance: Int
                if charA == charB {
                    currentDistance = last[indexB]
                } else {
                    currentDistance = min(last[indexB], last[indexB + 1], current[indexB]) + 1
                }
                current[indexB + 1] = currentDistance
            }
            last = current
        }
        return last.last!
    }
}
