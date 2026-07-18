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
    @State private var paymentDetermined: Bool = false
    @State private var paymentButtonLabel: PayWithApplePayButtonLabel?

    init(selectedAmount: SelectedAmount) {
        self.selectedAmount = selectedAmount
        payment = Payment()
    }

    var body: some View {
        VStack {
            Text(LocalString.payment_donation_reason_title)
                .font(.callout)
                .padding()

            Text(LocalString.payment_summary_page_title)
                .font(.largeTitle)
                .padding()
            
            if selectedAmount.isMonthly {
                Text(LocalString.payment_selection_option_monthly).font(.title)
                    .padding()
            } else {
                Text(LocalString.payment_selection_option_one_time).font(.title)
                    .padding()
            }
            Text(
                selectedAmount.value
                    .formatted(.currency(code: selectedAmount.currency.rawValue).locale(.current))
            )
                .font(.title)
                .bold()
            if paymentDetermined {
                if let paymentButtonLabel {
                    PayWithApplePayButton(
                        paymentButtonLabel,
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
                    Text(LocalString.payment_support_fallback_message)
                        .foregroundStyle(.red)
                        .font(.callout)
                }
            } else {
                LoadingProgressView()
                    .frame(width: 186, height: 44)
                    .padding()
            }
            Text(LocalString.payment_donation_is_encrypted)
                .multilineTextAlignment(.center)
                .font(.callout)
                .foregroundStyle(.tertiary)
                .padding(.vertical, 32)
                .padding(.horizontal, 48)
        }
        .task {
            paymentButtonLabel = await Payment.paymentButtonTypeAsync()
            paymentDetermined = true
        }
    }
}

#Preview {
    Rectangle()
        .background(Color.white)
        .frame(minWidth: .infinity, minHeight: .infinity)
        .sheet(isPresented: Binding<Bool>.constant(true)) {
            PaymentSummary(
                selectedAmount: SelectedAmount(value: 34, currency: .chf, isMonthly: true)
            )
            .presentationDetents([.fraction(0.83)])
        }
}
