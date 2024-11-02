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

struct CustomAmount: View {
    private let selected: PassthroughSubject<SelectedAmount?, Never>
    private let isMonthly: Bool
    @State private var customAmount: Double?
    @State private var customCurrency: String = Payment.defaultCurrencyCode
    @FocusState private var focusedField: FocusedField?
    private var currencies = Payment.currencyCodes

    public init(selected: PassthroughSubject<SelectedAmount?, Never>, isMonthly: Bool) {
        self.selected = selected
        self.isMonthly = isMonthly
    }

    var body: some View {
        VStack {
            Spacer()
            List {
                HStack {
                    TextField("Custom amount",
                              value: $customAmount,
                              format: .number.precision(.fractionLength(2)))
                    .focused($focusedField, equals: .customAmount)
#if os(iOS)
                    .padding(6)
                    .keyboardType(.decimalPad)
#else
                    .textFieldStyle(.plain)
                    .fontWeight(.bold)
                    .font(Font.headline)
                    .padding(4)
                    .border(Color.accentColor.opacity(0.618), width: 2)
#endif
                    Picker("", selection: $customCurrency) {
                        ForEach(currencies, id: \.self) {
                            Text(Locale.current.localizedString(forCurrencyCode: $0) ?? $0)
                        }
                    }
                }
            }.frame(maxHeight: 100)
            Spacer()
            HStack {
                Spacer()
                Button {
                    if let customAmount {
                        selected.send(
                            SelectedAmount(
                                value: customAmount,
                                currency: customCurrency,
                                isMonthly: isMonthly
                            )
                        )
                    }
                } label: {
                    Text("Confirm")
                }
                .buttonStyle(BorderedProminentButtonStyle())
                .padding()
                .disabled( customAmount == nil || (customAmount ?? 0) <= 0)
            }
            Spacer()
        }
        .task { @MainActor in
            focusedField = .customAmount
        }
    }

}

private enum FocusedField: String {
    case customAmount
}

#Preview {
    CustomAmount(selected: PassthroughSubject<SelectedAmount?, Never>(), isMonthly: true)
}

