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
import PassKit

struct PaymentSummary: View {

    let selectedAmount: SelectedAmount
    private let payment: Payment

    init(selectedAmount: SelectedAmount, onComplete: @escaping () -> Void) {
        self.selectedAmount = selectedAmount
        payment = Payment(onComplete: onComplete)
    }

    var body: some View {
        VStack {
            Text("Support Kiwix")
                .font(.largeTitle)
                .padding()
            if selectedAmount.isMonthly {
                Text("Monthly").font(.title)
                    .padding()
            } else {
                Text("One-time").font(.title)
                    .padding()
            }
            Text(selectedAmount.value.formatted(.currency(code: selectedAmount.currency))).font(.title).bold()
            if let buttonLabel = Payment.paymentButtonType() {
                PayWithApplePayButton(
                    buttonLabel,
                    request: payment.donationRequest(for: selectedAmount),
                    onPaymentAuthorizationChange: payment.onPaymentAuthPhase(phase:),
                    onMerchantSessionRequested: payment.onMerchantSessionUpdate
                )
                .frame(width: 186, height: 44)
                .padding()
            } else {
                Text("We are sorry, your device does not support Apple Pay.")
                    .foregroundStyle(.red)
                    .font(.callout)
            }
        }
    }
}

#Preview {
    PaymentSummary(selectedAmount: SelectedAmount(value: 34, currency: "CHF", isMonthly: true), onComplete: {})
}
