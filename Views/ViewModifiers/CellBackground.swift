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

enum CellBackground {
    #if os(macOS)
    private static let normal: Color = Color(nsColor: NSColor.controlBackgroundColor)
    private static let hover: Color = Color(nsColor: NSColor.selectedControlColor)
    private static let selected: Color = Color(nsColor: NSColor.controlAccentColor)
    private static let hoverSelected: Color = Color(nsColor: NSColor.controlAccentColor)
    #else
    private static let normal: Color = .secondaryBackground
    private static let hover: Color = .tertiaryBackground
    #endif
    
    static func colorFor(isHovering: Bool, isSelected: Bool = false) -> Color {
        if isSelected {
            isHovering ? hoverSelected : selected
        } else {
            isHovering ? hover : normal
        }
    }
    
    static let clipShapeRectangle = RoundedRectangle(cornerRadius: 12, style: .continuous)
}
