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

enum Resizer {

    static func fit(_ size: CGSize, into maxSize: CGSize) -> CGSize {
        let ratio = size.ratio
        if maxSize.ratio <= ratio {
            // subject is horizontal
            return CGSize(width: maxSize.width, height: maxSize.width / ratio)
        } else {
            return CGSize(width: maxSize.height * ratio, height: maxSize.height)
        }
    }
}

extension CGSize {
    var ratio: CGFloat {
        guard height != 0 else { return 1 }
        return width / height
    }
}
