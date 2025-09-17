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

import SwiftUI

#if os(iOS)

/// Backward compatible spacer for toolbar
struct SpacerBackCompatible: View {
    var body: some View {
        if #available(iOS 26, *) {
            EmptyView()
        } else {
            Spacer()
        }
    }
}
#else
struct SpacerBackCompatible: View {
    var body: some View {
        Spacer()
    }
}
#endif
