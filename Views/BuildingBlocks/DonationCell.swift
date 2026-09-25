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

struct DonationCell: View {
    @State private var isHovering: Bool = false
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(LocalString.payment_support_button_label)
                        .fontWeight(.semibold).foregroundColor(.primary).lineLimit(1)
                }
                Spacer()
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
                    .frame(height: 20)
            }
            
            Text(LocalString.payment_donation_cell_description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background {
            CellBackground.clipShapeRectangle
                .fill(Color.cyan.opacity(0.1682))
        }
        .modifier(LoadingOverlay(isLoading: isLoading))
        .onHover { self.isHovering = $0 }
        .accessibilityAddTraits(.isButton)
        .accessibilityElement()
        .accessibilityLabel(Self.cellAccessibilityLabel())
        .accessibilityAddTraits(.isButton)
    }
    
    static func cellAccessibilityLabel() -> String {
        [LocalString.payment_donate_title,
         LocalString.payment_donation_reason_title
        ].joined(separator: ", ")
    }
}
