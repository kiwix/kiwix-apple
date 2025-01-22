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

struct ListOfAmounts: View {
    let amountSelected: PassthroughSubject<SelectedAmount?, Never>

    @Binding public var isMonthly: Bool
    @State private var listState: ListState = .list
    #if os(macOS)
    @EnvironmentObject var formReset: FormReset
    #endif

    init(amountSelected: PassthroughSubject<SelectedAmount?, Never>, isMonthly: Binding<Bool>) {
        self.amountSelected = amountSelected
        _isMonthly = isMonthly
    }

    var body: some View {
        if case .customAmount = listState {
            CustomAmount(selected: amountSelected, isMonthly: isMonthly)
            #if os(macOS)
                .onReceive(formReset.objectWillChange) { _ in
                    reset()
                }
            #endif
        } else {
            listing()
            // doesn't need reset, since this is the default state
        }
    }

    private func reset() {
        listState = .list
    }

    private func listing() -> some View {
        let items = isMonthly ? Payment.monthlies : Payment.oneTimes
        let averageText: String = if isMonthly {
            LocalString.payment_selection_average_monthly_donation_subtitle
        } else {
            LocalString.payment_selection_last_year_average_subtitle
        }
        let defaultCurrency: String = Payment.defaultCurrencyCode
        return List {
            ForEach(items) { amount in
                Button(
                    action: {
                        amountSelected.send(
                            SelectedAmount(
                                value: amount.value,
                                currency: defaultCurrency,
                                isMonthly: isMonthly
                            )
                        )
                    },
                    label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(amount.value, format: .currency(code: defaultCurrency))
                            .frame(alignment: .leading)
                        if amount.isAverage {
                            Text(averageText)
                                .foregroundColor(.secondary)
                                .font(.caption2)
                        }
                    }
                })
                .padding(6)
            }
            Button(action: {
                listState = .customAmount
            }, label: {
                Text(LocalString.payment_selection_custom_amount)
            })
            .padding(6)
        }
        #if os(macOS)
        .buttonStyle(LinkButtonStyle())
        #endif
    }
}

private enum ListState {
    case list
    case customAmount
}

#Preview {
    ListOfAmounts(
        amountSelected: PassthroughSubject<SelectedAmount?, Never>(),
        isMonthly: Binding<Bool>.constant(true)
    )
}
