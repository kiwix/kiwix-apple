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

struct SettingSection<Content: View>: View {
    let name: String
    let alignment: VerticalAlignment
    let leftWidth: CGFloat
    var content: () -> Content

    init(
        name: String,
        alignment: VerticalAlignment = .firstTextBaseline,
        leftWidth: CGFloat = 100,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.name = name
        self.alignment = alignment
        self.leftWidth = leftWidth
        self.content = content
    }

    var body: some View {
        HStack(alignment: alignment) {
            Text("\(name):").frame(width: leftWidth, alignment: .trailing)
            VStack(alignment: .leading, spacing: 16, content: content)
            Spacer()
        }
    }
}
