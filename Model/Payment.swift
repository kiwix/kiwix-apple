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

struct Payment {

    static let merchantId = "merchant.org.kiwix"
    static let supportedNetworks: [PKPaymentNetwork] = [.masterCard, .visa, .discover, .amex, .chinaUnionPay, .electron, .girocard]
    static let capabilities: PKMerchantCapability = [.threeDSecure, .credit, .debit, .emv]

    func donationRequest() -> PKPaymentRequest {
        let request = PKPaymentRequest()
        request.merchantIdentifier = Self.merchantId
        request.merchantCapabilities = Self.capabilities
        request.countryCode = "CH"
        request.currencyCode = "USD"
        request.supportedNetworks = Self.supportedNetworks
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "Kiwix", amount: 15, type: .final)
        ]
        return request
    }

    func onPaymentAuthPhase(phase: PayWithApplePayButtonPaymentAuthorizationPhase) {
        debugPrint("onPaymentAuthPhase: \(phase)")
        switch phase {
        case .willAuthorize:
            break
        case .didAuthorize(let payment, let resultHandler):
//            server.process(with: payment) { serverResult in
//                guard case .success = serverResult else {
//                    // handle error
//                    resultHandler(PKPaymentAuthorizationResult(status: .failure, errors: Error()))
//                    return
//                }
//                // handle success
//                let result = PKPaymentAuthorizationResult(status: .success, errors: nil)
//                resultHandler(result)
//            }
            break
        case .didFinish:
            break
        @unknown default:
            break
        }
    }

    @available(macOS 13.0, *)
    func onMerchantSessionUpdate() async -> PKPaymentRequestMerchantSessionUpdate {
        .init(status: .success, merchantSession: nil)
    }
}
