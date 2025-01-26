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

struct PaymentResultPopUp: View {

    @Environment(\.dismiss) var dismiss
    #if os(iOS)
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    #endif

    let state: State

    enum State {
        case thankYou
        case error
    }

    var body: some View {
        Group {
            #if os(iOS)
            // iPhone Landscape
            if verticalSizeClass == .compact {
                // needs a close button
                closeButton
            }
            #endif
            VStack(spacing: 16) {
                switch state {
                case .thankYou:
                    Text(LocalString.payment_success_title)
                        .font(.title)
                    Text(LocalString.payment_success_description)
                        .font(.headline)
                case .error:
                    Text(LocalString.payment_error_title)
                        .font(.title)
                    Text(LocalString.payment_error_description)
                        .font(.headline)
                }

            }
            .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    var closeButton: some View {
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
}

#Preview {
    PaymentResultPopUp(state: .thankYou)
}
