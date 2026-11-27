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
import Testing
@testable import Kiwix

struct StripeKiwixTests {

    private struct EncodedPayload: Decodable {
        let amount: Int
        let currency: String
    }

    @Test(
        "SelectedPaymentAmount rounds major-unit amounts to exact minor units",
        arguments: [
            (5.00, 500),
            (5.02, 502),
            (5.06, 506),
            (5.10, 510),
            (8.20, 820),
            (14.56, 1456),
            (19.99, 1999),
            (29.99, 2999),
            (999_999.99, 99_999_999)
        ]
    )
    func selectedPaymentAmountRoundsWithoutTruncation(value: Double, expectedCents: Int) throws {
        let selectedAmount = SelectedAmount(value: value, currency: .usd, isMonthly: false)
        let payload = SelectedPaymentAmount(
            from: selectedAmount,
            emailAddress: "donor@example.org",
            deviceName: "iPhone"
        )
        #expect(payload.amount == expectedCents)

        let data = try JSONEncoder().encode(payload)
        let decoded = try JSONDecoder().decode(EncodedPayload.self, from: data)
        #expect(decoded.amount == expectedCents)
        #expect(decoded.currency == "USD")
    }

    @Test("All two-decimal amounts from 5.00 to 29.99 encode to exact cents")
    func allTwoDecimalAmountsBetweenFiveAndThirtyEncodeExactCents() {
        for expectedCents in 500...2999 {
            let value = Double(expectedCents) / 100.0
            let selectedAmount = SelectedAmount(value: value, currency: .eur, isMonthly: true)
            let payload = SelectedPaymentAmount(
                from: selectedAmount,
                emailAddress: "donor@example.org",
                deviceName: "iPad"
            )
            #expect(payload.amount == expectedCents)
        }
    }

    @Test("Non-finite inputs safely resolve to zero cents")
    func nonFiniteInputsReturnZero() {
        #expect(SelectedPaymentAmount.amountInCents(from: .nan) == 0)
        #expect(SelectedPaymentAmount.amountInCents(from: .infinity) == 0)
        #expect(SelectedPaymentAmount.amountInCents(from: -.infinity) == 0)
    }
}
