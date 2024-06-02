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

enum ByteRanges {

    static func rangesFor(contentLength: UInt, rangeSize size: UInt) -> [ClosedRange<UInt>] {
        guard size > 0 else {
            return []
        }
        return stride(from: 0, to: contentLength, by: UInt.Stride(size)).map { point in
            let endOfRange = min(contentLength - 1, point + size - 1)
            return point...endOfRange
        }
    }
}
