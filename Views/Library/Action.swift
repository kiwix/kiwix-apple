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

struct Action: View {
    let title: String
    let isDestructive: Bool
    let action: @MainActor () async -> Void

    init(title: String,
         isDestructive: Bool = false,
         action: @MainActor @escaping () async -> Void = {}
    ) {
        self.title = title
        self.isDestructive = isDestructive
        self.action = action
    }

    var body: some View {
        AsyncButton(action: action, label: {
            HStack {
                Spacer()
                Text(title)
                    .fontWeight(.medium)
                    .foregroundColor(isDestructive ? .red : nil)
                Spacer()
            }
        })
    }
}
