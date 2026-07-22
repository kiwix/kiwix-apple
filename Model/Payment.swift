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
@preconcurrency import PassKit
import SwiftUI
import Combine
@preconcurrency import StripeApplePay
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
        case errorAlreadyHasSubscription
    }

    #if DEBUG
    static let kiwixPaymentServer = URL(string: "https://staging.api.donation.kiwix.org/v1/stripe")!
    // swiftlint:disable:next line_length
    static let subscriptionTokenCallbackURL = URL(string: "http://staging.api.donation.kiwix.org/v1/stripe/token-callback")!
    #else
    static let kiwixPaymentServer = URL(string: "https://api.donation.kiwix.org/v1/stripe")!
    static let subscriptionTokenCallbackURL = URL(string: "http://api.donation.kiwix.org/v1/stripe/token-callback")!
    #endif
    static let merchantSessionURL = URL(string: "https://apple-pay-gateway.apple.com" )!
    static let merchantId = "merchant.org.kiwix.apple"
    static let paymentSubscriptionManagingURL = "https://www.kiwix.org"
    // optional to be implemented:
    // for reference see:
    // https://developer.apple.com/documentation/merchanttokennotificationservices
    static let supportedNetworks: [PKPaymentNetwork] = [
        .amex,
        PKPaymentNetwork.pagoBancomat,
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
    static let capabilities: PKMerchantCapability = .threeDSecure

    /// NOTE: consider that these currencies support double precision, eg: 5.25 USD.
    /// Revisit `SelectedAmount`, and `SelectedPaymentAmount`
    /// before adding a zero-decimal currency such as: ¥100
    enum Currency: String, CaseIterable, Identifiable {
        case usd = "USD"
        case eur = "EUR"
        case chf = "CHF"
        
        var id: String { rawValue }
        
        var label: String {
            switch self {
            case .usd: "$ USD"
            case .eur: "€ EUR"
            case .chf: "  CHF"
            }
        }
    }
    static let defaultCurrencyCode = Currency.usd
    private static let minimumAmount: Double = 5
    /// The Sripe `amount` value supports up to eight digits
    /// (e.g., a value of 999_999_99 for a USD charge of $999,999.99).
    /// see: https://docs.stripe.com/api/payment_intents/object#payment_intent_object-amount
    static let maximumAmount: Int = 999_999_99
    static func validRangeOf(_ amount: Double) -> ValidRange {
        if amount < minimumAmount {
            return .below
        }
        if amount > Double(maximumAmount)/100.0 {
            return .above
        }
        return .valid
    }
    
    enum ValidRange {
        case valid
        case below
        case above
        
        var isValid: Bool {
            self == .valid
        }
    }
    
    static var errorMessageBelow: String {
        "Minimum is \(minimumAmount.formatted(.number.precision(.fractionLength(2)).locale(.current)))"
    }
    
    static var errorMessageAbove: String {
        let maxDouble = Double(maximumAmount)/100.0
        return "Maximum is \(maxDouble.formatted(.number.precision(.fractionLength(2)).locale(.current)))"
    }

    /// Checks Apple Pay capabilities, and returns the button label accordingly
    /// - Returns: Setup button if no cards added yet,
    /// nil if Apple Pay is not supported
    /// or donation button, if all is OK
    static private func paymentButtonType() -> PaymentButtonType? {
        // only kiwix app is supporting donations atm.
        guard case .kiwix = AppType.current else { return nil }
        
        if PKPaymentAuthorizationController.canMakePayments() {
            return PaymentButtonType.donate
        }
        if PKPaymentAuthorizationController.canMakePayments(
            usingNetworks: Payment.supportedNetworks,
            capabilities: Payment.capabilities) {
            return PaymentButtonType.setUp
        }
        return nil
    }
    
    /// Sendable version of PayWithApplePayButtonLabel
    private enum ApplePaymentLabelType: Sendable {
        case donate
        case setUp
    }
    
    /// Async version of ``paymentButtonType()`` with low priority
    /// - Returns: Setup button if no cards added yet,
    /// nil if Apple Pay is not supported
    /// or donation button, if all is OK
    static func paymentButtonTypeAsync() async -> PaymentButtonType? {
        let task = Task<PaymentButtonType?, Never>(priority: .low) {
            Self.paymentButtonType()
        }
        guard let buttonLabel = await task.result.get() else {
            return nil
        }
        switch buttonLabel {
        case .donate:
            return PaymentButtonType.donate
        case .setUp:
            return PaymentButtonType.setUp
        }
    }

    func donationRequest(for selectedAmount: SelectedAmount) -> PKPaymentRequest {
        let request = PKPaymentRequest()
        request.merchantIdentifier = Self.merchantId
        request.countryCode = Locale.Region.switzerland.identifier
        request.currencyCode = selectedAmount.currency.rawValue
        request.supportedNetworks = Self.supportedNetworks
        request.merchantCapabilities = Self.capabilities
        // We have to require the shipping email, otherwise we don't get any email at all!
        request.requiredShippingContactFields = [.emailAddress]
        request.requiredBillingContactFields = [.emailAddress]
        request.recurringPaymentRequest = recurringPayment(for: selectedAmount)
        request.paymentSummaryItems = summartItems(for: selectedAmount)
        return request
    }

    func onPaymentAuthPhase(selectedAmount: SelectedAmount,
                            phase: PayWithApplePayButtonPaymentAuthorizationPhase) {
        switch phase {
        case .willAuthorize:
            Log.Payment.info("onPaymentAuthPhase: .willAuthorize")
        // Important! do not attempt to do anything UI related after
        // the resultHandler is called, it will block the Apple Pay pop-up
        // and only background / foreground-ing the app will unblock it
        case .didAuthorize(let payment, let resultHandler):
            Log.Payment.info("onPaymentAuthPhase: .didAuthorize")
            // call our server to get payment / setup intent and return the client.secret
            Task { @MainActor [resultHandler] in
                let paymentServer = StripeKiwix(endPoint: Self.kiwixPaymentServer)
                do {
                    let publicKey = try await paymentServer.publishableKey()
                    StripeAPI.setDefault(publishableKey: publicKey)
                } catch let serverError {
                    NotificationCenter.donationResult(.error)
                    resultHandler(.init(status: .failure, errors: [serverError]))
                    return
                }
                // Note: the returnURL path is not needed, we are never leaving the app. According to stripe docs:
                // "The URL to redirect your customer back to after they authenticate or cancel
                // their payment on the payment method’s app or site.
                // This should probably be a URL that opens your iOS app."
                let stripe = StripeApplePaySimple()
                let endPoint = paymentServer.endPoint
                let email = payment.shippingContact?.emailAddress ?? ""
                let result = await stripe.complete(payment: payment,
                                                   returnURLPath: nil,
                                                   usingClientSecretProvider: { @Sendable in
                    await StripeKiwix
                        .clientSecretForPayment(endPoint: endPoint,
                                                selectedAmount: selectedAmount,
                                                email: email,
                                                deviceName: Device.current.rawValue
                        )
                }, withAPI: StripeAsyncAPI())

                switch result.status {
                case .success:
                    NotificationCenter.donationResult(.thankYou)
                case .failure:
                    if let firstError = result.errors.first as? NSError,
                       firstError.domain == "Kiwix.StripeKiwix.StripeError",
                       firstError.code == StripeKiwix.StripeError.errorAlreadyHasSubscription.rawValue {
                        NotificationCenter.donationResult(.errorAlreadyHasSubscription)
                    } else {
                        NotificationCenter.donationResult(.error)
                    }
                default:
                    NotificationCenter.donationResult(.error)
                }
                Log.Payment.info("onPaymentAuthPhase: .didAuthorize: \(result.status == .success, privacy: .public)")
                resultHandler(result)
            }
        case .didFinish:
            Log.Payment.info("onPaymentAuthPhase: .didFinish")
        @unknown default:
            Log.Payment.error("onPaymentAuthPhase: @unknown default")
        }
    }

    @MainActor
    func onMerchantSessionUpdate() async -> PKPaymentRequestMerchantSessionUpdate {
        guard let session = await StripeKiwix.stripeSession(endPoint: Self.kiwixPaymentServer) else {
            NotificationCenter.donationResult(.error)
            return .init(status: .failure, merchantSession: nil)
        }
        return .init(status: .success, merchantSession: session)
    }

    private func recurringPayment(for selectedAmount: SelectedAmount) -> PKRecurringPaymentRequest? {
        guard selectedAmount.isMonthly else { return nil }
        let payRequest = PKRecurringPaymentRequest(
            paymentDescription: LocalString.payment_description_label,
            regularBilling: .init(
                label: LocalString.payment_monthly_support_label,
                amount: NSDecimalNumber(value: selectedAmount.value),
                type: .final
            ),
            managementURL: URL(string: Self.paymentSubscriptionManagingURL)!
        )
        payRequest.regularBilling.intervalUnit = .month
        payRequest.tokenNotificationURL = Self.subscriptionTokenCallbackURL
        return payRequest
    }

    private func summartItems(for selectedAmount: SelectedAmount) -> [PKPaymentSummaryItem] {
        let item: PKPaymentSummaryItem
        if selectedAmount.isMonthly {
            let recurringItem = PKRecurringPaymentSummaryItem(label: LocalString.payment_monthly_support_label,
                                                 amount: NSDecimalNumber(value: selectedAmount.value),
                                                 type: .final)
            recurringItem.startDate = Date() // starts now
            recurringItem.intervalUnit = .month
            recurringItem.endDate = nil // never ending
            item = recurringItem
        } else {
            item = PKPaymentSummaryItem(label: LocalString.payment_summary_title,
                                        amount: NSDecimalNumber(value: selectedAmount.value),
                                        type: .final)
        }
        return [item]
    }
}

private enum MerchantSessionError: Error {
    case invalidStatus
}
