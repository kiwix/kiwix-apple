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

/// Add padding around the modified view. On iOS, the padding is adjusted so that the modified view align with the search bar.
struct GridCommon: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    let edges: Edge.Set?

    init(edges: Edge.Set? = nil) {
        self.edges = edges
    }

    func body(content: Content) -> some View {
        #if os(macOS)
        ScrollView {
            content.padding(edges ?? .all)
        }
        #elseif os(iOS)
        GeometryReader { proxy in
            ScrollView {
                content.padding(
                    edges ?? (
                        horizontalSizeClass == .compact || verticalSizeClass == .compact ? [.horizontal, .bottom] : .all
                    ),
                    proxy.size.width > 380 && verticalSizeClass == .regular ? 20 : 16
                )
            }
        }
        #endif
    }
}

