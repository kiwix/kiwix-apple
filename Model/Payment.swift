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
import PassKit
import SwiftUI
import Combine
import StripeApplePay
import os

/// Payment processing based on:
/// Apple-Pay button:
/// https://developer.apple.com/documentation/passkit_apple_pay_and_wallet/apple_pay#2872687
/// as described in: What’s new in Wallet and Apple Pay from WWDC 2022
/// (https://developer.apple.com/videos/play/wwdc2022/10041/)
///
/// Combined with Stripe's lightweight Apple Pay framework
/// https://github.com/stripe/stripe-ios/blob/master/StripeApplePay/README.md
/// based on the App Clip example project:
/// https://github.com/stripe/stripe-ios/tree/master/Example/AppClipExample
///
/// Whereas the Stripe SDK is based on the older
/// PKPaymentAuthorizationController (before PayWithApplePayButton was available)
/// https://developer.apple.com/documentation/passkit_apple_pay_and_wallet/apple_pay#2870963
///
/// The Stripe SDK has been brought up to date (with 2022 WWDC changes)
/// and modified to be compatible with macOS as well, see SPM dependencies
/// https://github.com/CodeLikeW/stripe-apple-pay
/// https://github.com/CodeLikeW/stripe-core
struct Payment {

    enum FinalResult {
        case thankYou
        case error
    }

    /// Decides if the Thank You / Error pop up should be shown
    /// - Returns: `FinalResult` only once
    @MainActor
    static func showResult() -> FinalResult? {
        // make sure `true` is "read only once"
        let value = Self.finalResult
        Self.finalResult = nil
        return value
    }
    @MainActor
    static private var finalResult: Payment.FinalResult?

    let completeSubject = PassthroughSubject<Void, Never>()

//    static let kiwixPaymentServer = URL(string: "https://api.donation.kiwix.org/v1/stripe")!
    static let kiwixPaymentServer = URL(string: "http://192.168.100.42:4242")!
    static let merchantSessionURL = URL(string: "https://apple-pay-gateway.apple.com" )!
    static let merchantId = "merchant.org.kiwix.apple"
    static let paymentSubscriptionManagingURL = "https://www.kiwix.org"
    static let supportedNetworks: [PKPaymentNetwork] = [
        .amex,
        .bancomat,
        .bancontact,
        .cartesBancaires,
        .chinaUnionPay,
        .dankort,
        .discover,
        .eftpos,
        .electron,
        .elo,
        .girocard,
        .interac,
        .idCredit,
        .JCB,
        .mada,
        .maestro,
        .masterCard,
        .mir,
        .privateLabel,
        .quicPay,
        .suica,
        .visa,
        .vPay
    ]
    static let capabilities: PKMerchantCapability = [.threeDSecure, .credit, .debit, .emv]

    /// NOTE: consider that these currencies support double precision, eg: 5.25 USD.
    /// Revisit `SelectedAmount`, and `SelectedPaymentAmount`
    /// before adding a zero-decimal currency such as: ¥100
    static let currencyCodes = ["USD", "EUR", "CHF"]
    static let defaultCurrencyCode = "USD"
    private static let minimumAmount: Double = 5
    /// The Sripe `amount` value supports up to eight digits
    /// (e.g., a value of 99999999 for a USD charge of $999,999.99).
    /// see: https://docs.stripe.com/api/payment_intents/object#payment_intent_object-amount
    static let maximumAmount: Int = 99999999
    static func isInValidRange(amount: Double?) -> Bool {
        guard let amount else { return false }
        return minimumAmount <= amount && amount <= Double(maximumAmount)*100.0
    }

    static let oneTimes: [AmountOption] = [
        .init(value: 10),
        .init(value: 34, isAverage: true),
        .init(value: 50)
    ]

    static let monthlies: [AmountOption] = [
        .init(value: 5),
        .init(value: 8, isAverage: true),
        .init(value: 10)
    ]

    /// Checks Apple Pay capabilities, and returns the button label accrodingly
    /// Setup button if no cards added yet,
    /// nil if Apple Pay is not supported
    /// or donation button, if all is OK
    static func paymentButtonType() -> PayWithApplePayButtonLabel? {
        if PKPaymentAuthorizationController.canMakePayments() {
            return PayWithApplePayButtonLabel.donate
        }
        if PKPaymentAuthorizationController.canMakePayments(
            usingNetworks: Payment.supportedNetworks,
            capabilities: Payment.capabilities) {
            return PayWithApplePayButtonLabel.setUp
        }
        return nil
    }

    func donationRequest(for selectedAmount: SelectedAmount) -> PKPaymentRequest {
        let request = PKPaymentRequest()
        request.merchantIdentifier = Self.merchantId
        request.merchantCapabilities = Self.capabilities
        request.countryCode = "CH"
        request.currencyCode = selectedAmount.currency
        request.supportedNetworks = Self.supportedNetworks
        request.merchantCapabilities = .threeDSecure
        request.requiredBillingContactFields = [.emailAddress]
        let recurring: PKRecurringPaymentRequest? = if selectedAmount.isMonthly {
            PKRecurringPaymentRequest(paymentDescription: "payment.description.label".localized,
                                      regularBilling: .init(label: "payment.monthly_support.label".localized,
                                                            amount: NSDecimalNumber(value: selectedAmount.value),
                                                            type: .final),
                                      managementURL: URL(string: Self.paymentSubscriptionManagingURL)!)
        } else {
            nil
        }
        request.recurringPaymentRequest = recurring
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(
                label: "payment.summary.title".localized,
                amount: NSDecimalNumber(value: selectedAmount.value),
                type: .final
            )
        ]
        return request
    }

    func onPaymentAuthPhase(selectedAmount: SelectedAmount,
                            phase: PayWithApplePayButtonPaymentAuthorizationPhase) {
        switch phase {
        case .willAuthorize:
            os_log("onPaymentAuthPhase: .willAuthorize")
        case .didAuthorize(let payment, let resultHandler):
            os_log("onPaymentAuthPhase: .didAuthorize")
            // call our server to get payment / setup intent and return the client.secret
            Task { @MainActor [resultHandler] in
                let paymentServer = StripeKiwix(endPoint: Self.kiwixPaymentServer,
                                                payment: payment)
                do {
                    let publicKey = try await paymentServer.publishableKey()
                    StripeAPI.defaultPublishableKey = publicKey
                } catch let serverError {
                    Self.finalResult = .error
                    resultHandler(.init(status: .failure, errors: [serverError]))
                    return
                }
                // we should update the return path for confirmations
                // see: https://github.com/kiwix/kiwix-apple/issues/1032
                let stripe = StripeApplePaySimple()
                let result = await stripe.complete(payment: payment,
                                                   returnURLPath: nil,
                                                   usingClientSecretProvider: {
                    await paymentServer.clientSecretForPayment(selectedAmount: selectedAmount)
                })
                // calling any UI refreshing state / subject from here
                // will block the UI in the payment state forever
                // therefore it's defered via static finalResult
                switch result.status {
                case .success:
                    Self.finalResult = .thankYou
                case .failure:
                    Self.finalResult = .error
                default:
                    Self.finalResult = nil
                }
                resultHandler(result)
                os_log("onPaymentAuthPhase: .didAuthorize: \(result.status == .success)")
            }
        case .didFinish:
            os_log("onPaymentAuthPhase: .didFinish")
            completeSubject.send(())
        @unknown default:
            os_log("onPaymentAuthPhase: @unknown default")
        }

    }

    @available(macOS 13.0, *)
    func onMerchantSessionUpdate() async -> PKPaymentRequestMerchantSessionUpdate {
        guard let session = await StripeKiwix.stripeSession(endPoint: Self.kiwixPaymentServer) else {
            await MainActor.run {
                Self.finalResult = .error
            }
            return .init(status: .failure, merchantSession: nil)
        }
        return .init(status: .success, merchantSession: session)
    }
}

private enum MerchantSessionError: Error {
    case invalidStatus
}
