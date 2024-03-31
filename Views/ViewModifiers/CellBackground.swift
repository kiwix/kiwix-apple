/*
 * This file is part of Kiwix for iOS & macOS.
 *
 * Kiwix is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * any later version.
 *
 * Kiwix is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Kiwix; If not, see https://www.gnu.org/licenses/.
*/

import SwiftUI

struct CellBackground: ViewModifier {
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    let isHovering: Bool

    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var backgroundColor: Color {
        switch (colorScheme, isHovering) {
        case (.dark, true):
            #if os(macOS)
            return Color.background
            #elseif os(iOS)
            return Color.secondaryBackground
            #endif
        case (.dark, false):
            return Color.tertiaryBackground
        case (.light, true):
            return Color(white: 0.9)
        case (.light, false), (_, _):
            #if os(macOS)
            return Color.white
            #elseif os(iOS)
            return Color(white: 0.96)
            #endif
        }
    }
}
