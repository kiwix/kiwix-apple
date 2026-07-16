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
    enum State {
        case thankYou
        case error
        case errorAlreadyHasSubscription
    }

    @Environment(\.dismiss) var dismiss
    #if os(iOS)
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    #endif
    
    private let title: String
    private let description: String
    
    init(state: State) {
        switch state {
        case .thankYou:
            title = LocalString.payment_success_title
            description = LocalString.payment_success_description
        case .error:
            title = LocalString.payment_error_title
            description = LocalString.payment_error_description
        case .errorAlreadyHasSubscription:
            title = LocalString.payment_error_already_subscribed_title
            description = LocalString.payment_error_already_subscribed_description
        }
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
                Text(title).padding()
                    .font(.title)
                Text(description).padding()
                    .font(.headline)
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
            .accessibilityIdentifier("close_payment_button")
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
