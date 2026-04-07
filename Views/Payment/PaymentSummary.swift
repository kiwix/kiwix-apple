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
import Combine

#if os(iOS) || os(macOS)
import PassKit
#endif

struct PaymentSummary: View {

    @Environment(\.dismiss) var dismiss

    private let selectedAmount: SelectedAmount
    private let payment: Payment
    private let onComplete: @MainActor () -> Void
    @State private var paymentDetermined: Bool = false
    @State private var paymentButtonLabel: Payment.ButtonLabelType?
    #if os(macOS)
    @State private var applePayCoordinator: MacApplePayCoordinator
    #endif

    init(selectedAmount: SelectedAmount,
         onComplete: @escaping @MainActor () -> Void) {
        self.selectedAmount = selectedAmount
        self.onComplete = onComplete
        let payment = Payment()
        self.payment = payment
        #if os(macOS)
        _applePayCoordinator = State(
            initialValue: MacApplePayCoordinator(
                selectedAmount: selectedAmount,
                payment: payment
            )
        )
        #endif
    }

    var body: some View {
        VStack {
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
            Text(selectedAmount.value.formatted(.currency(code: selectedAmount.currency))).font(.title).bold()
            #if os(iOS)
            if paymentDetermined {
                if let paymentButtonLabel {
                    PayWithApplePayButton(
                        paymentButtonLabel.payWithApplePayButtonLabel,
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
            }
            #elseif os(macOS)
            if paymentDetermined {
                if let paymentButtonLabel {
                    MacApplePayButton(
                        type: paymentButtonLabel.paymentButtonType,
                        action: applePayCoordinator.present
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
            }
            #endif
        }.onReceive(payment.completeSubject) {
            onComplete()
        }
        .task {
            paymentButtonLabel = await Payment.paymentButtonTypeAsync()
            paymentDetermined = true
        }
        #if os(macOS)
        .withHostingWindow { window in
            applePayCoordinator.presentationWindow = window
        }
        #endif
    }
}

#if os(macOS)
private struct MacApplePayButton: NSViewRepresentable {
    let type: PKPaymentButtonType
    let action: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    func makeNSView(context: Context) -> PKPaymentButton {
        let button = PKPaymentButton(paymentButtonType: type, paymentButtonStyle: .automatic)
        button.target = context.coordinator
        button.action = #selector(Coordinator.onTap)
        return button
    }

    func updateNSView(_ button: PKPaymentButton, context: Context) {
        button.target = context.coordinator
        button.action = #selector(Coordinator.onTap)
    }

    final class Coordinator: NSObject {
        private let action: () -> Void

        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc func onTap() {
            action()
        }
    }
}

private final class MacApplePayCoordinator: NSObject, PKPaymentAuthorizationControllerDelegate, @unchecked Sendable {
    let selectedAmount: SelectedAmount
    let payment: Payment
    var presentationWindow: NSWindow?

    private var controller: PKPaymentAuthorizationController?

    init(selectedAmount: SelectedAmount, payment: Payment) {
        self.selectedAmount = selectedAmount
        self.payment = payment
    }

    func present() {
        let controller = PKPaymentAuthorizationController(paymentRequest: payment.donationRequest(for: selectedAmount))
        controller.delegate = self
        self.controller = controller
        controller.present { [weak self] success in
            guard let self, !success else { return }
            Log.Payment.error("paymentAuthorizationController.presentWithCompletion failed")
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.controller = nil
                self.payment.authorizationPresentationDidFail()
            }
        }
    }

    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.controller = nil
                self.payment.authorizationDidFinish()
            }
        }
    }

    func paymentAuthorizationControllerWillAuthorizePayment(_ controller: PKPaymentAuthorizationController) {
        Log.Payment.info("paymentAuthorizationController: will authorize")
    }

    func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController,
                                        didRequestMerchantSessionUpdate handler: @escaping (PKPaymentRequestMerchantSessionUpdate) -> Void) {
        Task { @MainActor [payment] in
            handler(await payment.onMerchantSessionUpdate())
        }
    }

    func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController,
                                        didAuthorizePayment authorizedPayment: PKPayment,
                                        handler: @escaping (PKPaymentAuthorizationResult) -> Void) {
        Task { @MainActor [payment, selectedAmount] in
            let result = await payment.authorize(payment: authorizedPayment, selectedAmount: selectedAmount)
            handler(result)
            Log.Payment.info("paymentAuthorizationController: didAuthorize: \(result.status == .success, privacy: .public)")
        }
    }

    func presentationWindow(for controller: PKPaymentAuthorizationController) -> NSWindow? {
        presentationWindow
    }
}
#endif

#Preview {
    PaymentSummary(
        selectedAmount: SelectedAmount(value: 34,
                                       currency: "CHF",
                                       isMonthly: true),
        onComplete: {}
    )
}
