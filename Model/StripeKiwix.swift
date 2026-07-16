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
import os

struct StripeKiwix {
    
    /// The very maximum amount stripe payment intent can handle
    /// see: https://docs.stripe.com/api/payment_intents/object#payment_intent_object-amount
    static let maxAmount: Int = 999999999

    enum StripeError: Int, Error {
        case serverError
        case errorAlreadyHasSubscription
    }

    let endPoint: URL

    func publishableKey() async throws -> String {
        let (data, response) = try await URLSession.shared.data(from: endPoint.appending(path: "config"))
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw StripeError.serverError
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let json = try decoder.decode(PublishableKey.self, from: data)
        return json.publishableKey
    }
    
    private struct ErrorData: Decodable {
        let detail: String
    }

    nonisolated static func clientSecretForPayment(
        endPoint: URL,
        selectedAmount: SelectedAmount,
        email: String,
        deviceName: String
    ) async -> Result<String, Error> {
        do {
            let requestPath = selectedAmount.isMonthly ? "setup-intent" : "payment-intent"
            var request = URLRequest(url: endPoint.appending(path: requestPath))
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder()
                .encode(SelectedPaymentAmount(from: selectedAmount,
                                              emailAddress: email,
                                              deviceName: deviceName))
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw StripeError.serverError
            }
            guard (200..<300).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 409 {
                        throw StripeError.errorAlreadyHasSubscription
                } else {
                    throw StripeError.serverError
                }
            }
            let json = try JSONDecoder().decode(ClientSecretKey.self, from: data)
            return .success(json.secret)
        } catch let serverError {
            return .failure(serverError)
        }
    }

    static func stripeSession(endPoint: URL) async -> PKPaymentMerchantSession? {
        do {
            var request = URLRequest(url: endPoint.appending(path: "payment-session"))
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            request.httpBody = try encoder.encode(SessionParams())
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else {
                throw StripeError.serverError
            }
            guard let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                Log.Payment.error("Merchant session not established: unable to decode server response")
                return nil
            }
            return PKPaymentMerchantSession(dictionary: dictionary)
        } catch let serverError {
            Log.Payment.error("Merchant session not established: \(serverError.localizedDescription, privacy: .public)")
            return nil
        }
    }
}

/// Response structure for GET {endPoint}/config
/// {"publishable_key":"pk_test_..."}
private struct PublishableKey: Decodable {
    let publishableKey: String
}

/// Response structure for POST {endPoint}/create-payment-intent
/// {"secret":"pi_..."}
private struct ClientSecretKey: Decodable {
    let secret: String
}

private struct SelectedPaymentAmount: Encodable {
    let amount: Int
    let currency: String
    let email: String
    let origin: String
    let lang: String = Locale.current.language.languageCode?.identifier ?? ""

    init(from selectedAmount: SelectedAmount, emailAddress: String, deviceName: String) {
        // Amount intended to be collected by this PaymentIntent.
        // A positive integer representing how much to charge in the smallest currency unit
        // (e.g., 100 cents to charge $1.00 or 100 to charge ¥100, a zero-decimal currency).
        // The minimum amount is $0.50 US or equivalent in charge currency.
        amount = Int(selectedAmount.value * 100.0)
        currency = selectedAmount.currency.rawValue
        origin = deviceName
        email = emailAddress
    }
}
private struct SessionParams: Encodable {
    let validationUrl = "apple-pay-gateway-cert.apple.com"
}
