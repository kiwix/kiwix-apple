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

struct MarkAsHalfSheet: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 13.0, iOS 16.0, *) {
            content.presentationDetents([.medium, .large])
        } else {
            /*
             HACK: Use medium as selection so that half sized sheets are consistently shown
             when tab manager button is pressed, user can still freely adjust sheet size.
            */
            content.backport.presentationDetents([.medium, .large], selection: .constant(.medium))
        }
    }
}

struct ToolbarRoleBrowser: ViewModifier {
    func body(content: Content) -> some View {
        #if os(macOS)
        content
        #elseif os(iOS)
        if #available(iOS 16.0, *) {
            content.toolbarRole(.browser)
        } else {
            content
        }
        #endif
    }
}
