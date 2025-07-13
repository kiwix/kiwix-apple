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
struct ShareButton: View {
    
    let buttonLabel: String = LocalString.common_button_share
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            Label {
                Text(buttonLabel)
            }  icon: {
                Image(systemName: "square.and.arrow.up")
            }
        }
    }
}
#endif

#if os(macOS)
struct ShareButton: View {
    
    let url: URL
    let relativeToView: NSView
    let origin: CGPoint
    let preferredEdge: NSRectEdge
    let buttonLabel: String = LocalString.common_button_share
    
    var body: some View {
        Button {
            Task {
                NSSharingServicePicker(items: [url]).show(
                    relativeTo: NSRect(
                        origin: origin,
                        size: CGSize(
                            width: 640,
                            height: 54
                        )
                    ),
                    of: relativeToView,
                    preferredEdge: preferredEdge
                )
            }
        } label: {
            Label {
                Text(buttonLabel)
            }  icon: {
                Image(systemName: "square.and.arrow.up")
            }
        }
    }
}

#endif
