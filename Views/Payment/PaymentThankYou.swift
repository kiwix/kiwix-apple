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

struct PaymentThankYou: View {

    @Environment(\.dismiss) var dismiss
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?

    var body: some View {
        Group {
            // iPhone Landscape
            if verticalSizeClass == .compact {
                // needs a close button
                HStack(alignment: .top) {
                    Spacer()
                    Button("", systemImage: "x.circle.fill") {
                        dismiss()
                    }
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .padding()
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            VStack(spacing: 16) {
                Text("payment.success.title".localized)
                    .font(.title)
                Text("payment.success.description".localized)
                    .font(.headline)
            }
            .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    PaymentThankYou()
}

