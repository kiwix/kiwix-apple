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
import SwiftUI

struct EllipsisAsyncButtonStyle: AsyncButtonStyle {
    @State private var animated = false

    func makeLabel(configuration: LabelConfiguration) -> some View {
        configuration.label
            .opacity(configuration.isLoading ? 0 : 1)
            .overlay {
                if #available(iOS 17.0, macOS 14.0, *) {
                    Image(systemName: "ellipsis")
                        .symbolEffect(.variableColor.iterative.dimInactiveLayers, options: .repeating, value: configuration.isLoading)
                        .font(.title)
                        .opacity(configuration.isLoading ? 1 : 0)
                } else {
                    Image(systemName: "ellipsis")
                        .font(.title)
                        .opacity(configuration.isLoading ? 1 : 0)
                }
            }
            .animation(.default, value: configuration.isLoading)
    }

    // Facultative, as ButtonKit comes with a default implementation for both.
    func makeButton(configuration: ButtonConfiguration) -> some View {
        configuration.button
    }
}

extension AsyncButtonStyle where Self == EllipsisAsyncButtonStyle {
    static var ellipsis: EllipsisAsyncButtonStyle {
        EllipsisAsyncButtonStyle()
    }
}
