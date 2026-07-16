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

struct CustomAmount: View {
    @Binding var selectedAmount: SelectedAmountState
    @State private var inputAmount: Double?
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack {
            Spacer()
            Group {
                inputField
            }
            .modifier(inputFieldModifier())
            Spacer()
        }
        .onChange(of: isFocused, initial: false) { oldValue, newValue in
            if !oldValue, newValue {
                updateWithCustom()
            }
        }
        .onChange(of: inputAmount) { _, _ in
            if isFocused, selectedAmount.isCustom {
                updateWithCustom()
            }
        }
        .onChange(of: selectedAmount) { (_, newValue: SelectedAmountState) in
            if case .predefined = newValue {
                // reset the whole custom part
                withAnimation {
                    isFocused = false
                    inputAmount = nil
                }
            }
        }
    }
    
    private func updateWithCustom() {
        withAnimation {
            switch inputAmount {
            case .none:
                selectedAmount = .editingCustom
            case let .some(amount):
                selectedAmount = .custom(amount: amount, valid: Payment.validRangeOf(amount))
            }
        }
    }

    @ViewBuilder
    private var inputField: some View {
        TextField(LocalString.payment_textfield_custom_amount_label,
                  value: $inputAmount,
                  format: .number.precision(.fractionLength(2)).locale(.current))
            .focused($isFocused)
            .focusable(isFocused, interactions: .activate)
            .padding()
#if os(iOS)
            .keyboardType(.decimalPad)
#else
            .textFieldStyle(.plain)
            .font(.title3)
#endif
    }
    
    private func inputFieldModifier() -> InputBackgroundModifier {
        switch selectedAmount {
        case .predefined:
            InputBackgroundModifier(.secondary.opacity(0.15))
        case .editingCustom, .custom(_, .valid):
            InputBackgroundModifier(.accentColor.opacity(0.25))
        case .custom(_, .above), .custom(_, .below):
            InputBackgroundModifier(.red.opacity(0.25))
        }
    }
}

private struct InputBackgroundModifier: ViewModifier {
    private let backgroundColor: Color
    init(_ backgroundColor: Color) {
        self.backgroundColor = backgroundColor
    }

    func body(content: Content) -> some View {
        content
            .background(
                backgroundColor,
                in: RoundedRectangle(
                    cornerSize: CGSize(width: 10, height: 10),
                    style: .continuous
                )
            )
    }
}
