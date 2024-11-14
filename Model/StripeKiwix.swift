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

struct StripeKiwix {
    
    /// The very maximum amount stripe payment intent can handle
    /// see: https://docs.stripe.com/api/payment_intents/object#payment_intent_object-amount
    static let maxAmount: Int = 999999999

    enum StripeError: Error {
        case serverError
    }

    let endPoint: URL
    let payment: PKPayment

    func publishableKey() async throws -> String {
        let (data, response) = try await URLSession.shared.data(from: endPoint.appending(path: "config"))
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw StripeError.serverError
        }
        let json = try JSONDecoder().decode(PublishableKey.self, from: data)
        return json.publishableKey
    }

    func clientSecretForPayment(selectedAmount: SelectedAmount) async -> Result<String, Error> {
        do {
            // TODO: for monthly this should create a setup-intent !
            var request = URLRequest(url: endPoint.appending(path: "create-payment-intent"))
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(SelectedPaymentAmount(from: selectedAmount))
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else {
                throw StripeError.serverError
            }
            let json = try JSONDecoder().decode(ClientSecretKey.self, from: data)
            return .success(json.clientSecret)
        } catch (let serverError) {
            return .failure(serverError)
        }
    }
}

/// Response structure for GET {endPoint}/config
/// {"publishableKey":"pk_test_..."}
private struct PublishableKey: Decodable {
    let publishableKey: String
}

/// Response structure for POST {endPoint}/create-payment-intent
/// {"clientSecret":"pi_..."}
private struct ClientSecretKey: Decodable {
    let clientSecret: String
}

private struct SelectedPaymentAmount: Encodable {
    let amount: Int
    let currency: String

    init(from selectedAmount: SelectedAmount) {
        // Amount intended to be collected by this PaymentIntent.
        // A positive integer representing how much to charge in the smallest currency unit
        // (e.g., 100 cents to charge $1.00 or 100 to charge ¥100, a zero-decimal currency).
        // The minimum amount is $0.50 US or equivalent in charge currency.
        amount = Int(selectedAmount.value * 100.0)
        currency = selectedAmount.currency
        assert(Payment.currencyCodes.contains(currency))
    }
}
