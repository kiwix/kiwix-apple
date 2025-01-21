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
import Combine

struct PaymentSummary: View {

    @Environment(\.dismiss) var dismiss

    private let selectedAmount: SelectedAmount
    private let payment: Payment
    private let onComplete: @MainActor () -> Void

    init(selectedAmount: SelectedAmount,
         onComplete: @escaping @MainActor () -> Void) {
        self.selectedAmount = selectedAmount
        self.onComplete = onComplete
        payment = Payment()
    }

    var body: some View {
        VStack {
            Text("payment.summary_page.title".localized)
                .font(.largeTitle)
                .padding()
            if selectedAmount.isMonthly {
                Text("payment.selection.option.monthly".localized).font(.title)
                    .padding()
            } else {
                Text("payment.selection.option.one_time".localized).font(.title)
                    .padding()
            }
            Text(selectedAmount.value.formatted(.currency(code: selectedAmount.currency))).font(.title).bold()
            if let buttonLabel = Payment.paymentButtonType() {
                PayWithApplePayButton(
                    buttonLabel,
                    request: payment.donationRequest(for: selectedAmount),
                    onPaymentAuthorizationChange: { phase in
                        payment.onPaymentAuthPhase(selectedAmount: selectedAmount,
                                                   phase: phase)
                    },
                    onMerchantSessionRequested: payment.onMerchantSessionUpdate
                )
                .frame(width: 186, height: 44)
                .padding()
            } else {
                Text("payment.support_fallback_message".localized)
                    .foregroundStyle(.red)
                    .font(.callout)
            }
        }.onReceive(payment.completeSubject) {
            onComplete()
        }
    }
}

#Preview {
    PaymentSummary(
        selectedAmount: SelectedAmount(value: 34,
                                       currency: "CHF",
                                       isMonthly: true),
        onComplete: {}
    )
}
