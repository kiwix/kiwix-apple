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

struct Payment {

    let completeSubject = PassthroughSubject<Bool, Never>()

    static let merchantSessionURL = URL(string: "https://apple-pay-gateway.apple.com" )!
    static let merchantId = "merchant.org.kiwix.apple"
    static let paymentSubscriptionManagingURL = "https://www.kiwix.org"
    static let supportedNetworks: [PKPaymentNetwork] = [
        .amex,
        .discover,
        .electron,
        .mada,
        .maestro,
        .masterCard,
        .visa,
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
        request.requiredBillingContactFields = [.postalAddress]
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

    func onPaymentAuthPhase(selectedAmount: SelectedAmount, phase: PayWithApplePayButtonPaymentAuthorizationPhase) {
        switch phase {
        case .willAuthorize:
            os_log("onPaymentAuthPhase: .willAuthorize")
            break
        case .didAuthorize(let payment, let resultHandler):
            os_log("onPaymentAuthPhase: .didAuthorize")
            // call our server to get payment / setup intent and return the client.secret
            // async http call...
            Task { [resultHandler] in

                let paymentServer = StripeKiwix(endPoint: URL(string: "http://192.168.100.7:4242")!,
                                                payment: payment)
                do {
                    let publicKey = try await paymentServer.publishableKey()
                    StripeAPI.defaultPublishableKey = publicKey
                } catch (let serverError) {
                    resultHandler(.init(status: .failure, errors: [serverError]))
                    return
                }
                let stripe = StripeApplePaySimple()
                let result = await stripe.complete(payment: payment,
                                                   returnURLPath: nil, // TODO: update the return path for confirmations
                                                   usingClientSecretProvider: { await paymentServer.clientSecretForPayment(selectedAmount: selectedAmount) } )
                resultHandler(result)
            }
        case .didFinish:
            os_log("onPaymentAuthPhase: .didFinish")
            completeSubject.send(true)
        @unknown default:
            os_log("onPaymentAuthPhase: @unknown default")
            break
        }
    }

    @available(macOS 13.0, *)
    func onMerchantSessionUpdate() async -> PKPaymentRequestMerchantSessionUpdate {
        var request = URLRequest(url: Self.merchantSessionURL)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode),
                  let dict = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                throw MerchantSessionError.invalidStatus
            }
            let session = PKPaymentMerchantSession(dictionary: dict)
            return .init(status: .success, merchantSession: session)
        } catch (let error) {
            os_log("Merchant session not established: %@", type: .debug, error.localizedDescription)
            return .init(status: .failure, merchantSession: nil)
        }
    }
}

private enum MerchantSessionError: Error {
    case invalidStatus
}
