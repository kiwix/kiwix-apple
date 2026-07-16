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

enum SelectedAmountState: Identifiable, Hashable, Equatable {
    case predefined(Double)
    case editingCustom
    case custom(amount: Double, valid: Payment.ValidRange)

    var amount: Double? {
        switch self {
        case let .predefined(amount): return amount
        case .editingCustom: return nil
        case .custom(_, .below), .custom(_, .above): return nil
        case let .custom(amount, .valid): return amount
        }
    }
    
    var isCustom: Bool {
        switch self {
        case .custom, .editingCustom: true
        case .predefined: false
        }
    }
    
    static let predefinedAmounts: [SelectedAmountState] = [5, 10, 25, 50].map { SelectedAmountState.predefined($0) }
    static let defaultForMonthly: SelectedAmountState = predefinedAmounts[1] // 10
    static let defaultForOneTime: SelectedAmountState = predefinedAmounts[2] // 25
    
    // MARK: conformance
    var id: String {
        switch self {
        case let .predefined(amount): "predefined_\(amount)"
        case .editingCustom: "editingCustom"
        case let .custom(amount: amount, _): "custom_\(amount)"
        }
    }
}

/// The validated final selection
struct SelectedAmount {
    let value: Double
    let currency: Payment.Currency
    let isMonthly: Bool
    
    init(value: Double, currency: Payment.Currency, isMonthly: Bool) {
        // make sure we won't go over Stripe's max amount
        self.value = min(value, Double(StripeKiwix.maxAmount) * 100.0)
        self.currency = currency
        self.isMonthly = isMonthly
    }
    
    init?(state: SelectedAmountState, currency: Payment.Currency, isMonthly: Bool) {
        guard let amount = state.amount else { return nil }
        self.init(value: amount, currency: currency, isMonthly: isMonthly)
    }
}
