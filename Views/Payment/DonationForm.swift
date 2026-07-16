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

private enum PaymentType: String, CaseIterable, Identifiable {
    case monthly
    case oneTime

    var id: String {
        rawValue
    }
    
    var isMonthly: Bool {
        self == .monthly
    }

    var label: String {
        switch self {
        case .oneTime:
            LocalString.payment_selection_option_one_time
        case .monthly:
            LocalString.payment_selection_option_monthly
        }
    }
}

struct DonationForm: View {
    @Environment(\.dismiss) var dismiss
    @State private var currencyType: Payment.Currency = .usd
    @State private var paymentType: PaymentType = .monthly
    @State private var selectedAmount: SelectedAmountState = Self.defaultFor(.monthly)
        
    private static func defaultFor(_ paymentType: PaymentType) -> SelectedAmountState {
        switch paymentType {
        case .monthly: SelectedAmountState.defaultForMonthly
        case .oneTime: SelectedAmountState.defaultForOneTime
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .center) {
                Group {
                    Group {
                        VStack(alignment: .center, spacing: 24) {
                            
                            Text(LocalString.payment_donation_reason_title)
                                .font(.callout)
#if os(iOS)
                            ControlGroup {
                                paymentTypePicker
                                currencyPicker
                            }
                            .controlGroupStyle(.navigation)
#else
                            HStack {
                                paymentTypePicker
                                currencyPicker
                            }
#endif
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120, maximum: 180))]) {
                                amountButtons
                            }
                            
                            CustomAmount(selectedAmount: $selectedAmount)
                            
                            switch selectedAmount {
                            case .custom(_, .above):
                                errorMessage(isAbove: true)
                            case .custom(_, .below):
                                errorMessage(isAbove: false)
                            default:
                                continueButton
                            }
                            
                            Spacer()
                        }
                    }
                    .frame(maxWidth: 540)
                    .padding()
                    .background(
                        .background,
                        in: RoundedRectangle(
                            cornerSize: CGSize(width: 10, height: 10),
                            style: .continuous
                        )
                    )
                }
                .padding()
                
                Spacer()
            }
        }
        .navigationTitle(LocalString.payment_donate_title)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                closeButton
            }
        }
        .toolbarRole(.navigationStack)
#endif
    }
    
    private func didUpdateType() {
        switch selectedAmount {
        case .predefined:
            // reset on a one-time / monthly change
            withAnimation {
                selectedAmount = Self.defaultFor(paymentType)
            }
        case .editingCustom, .custom:
            // do not change mid editing / customising
            break
        }
    }

    @ViewBuilder
    private var paymentTypePicker: some View {
        Picker("", selection: $paymentType) {
            ForEach(PaymentType.allCases) { type in
                Text(type.label)
                    .tag(type)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: paymentType) { _, _ in
            didUpdateType()
        }
    }

    @ViewBuilder
    private var currencyPicker: some View {
        Picker("", selection: $currencyType) {
            ForEach(Payment.Currency.allCases) { currency in
                Text(currency.label)
                    .tag(currency)
            }
        }
        .pickerStyle(.menu)
    }

    @ViewBuilder
    private var amountButtons: some View {
        ForEach(SelectedAmountState.predefinedAmounts, id: \.self) { predefined in
            Button {
                if predefined != selectedAmount {
                    withAnimation {
                        selectedAmount = predefined
                    }
                }
            } label: {
                // for the predefined ones it's OK to force unwrap
                amountLabel(predefined.amount!)
            }
            .modifier(PredifinedButtonModifier(isSelected: predefined == selectedAmount))
        }
    }

    private func amountLabel(_ amount: Double) -> some View {
        Text(amount.formatted(.number.precision(.fractionLength(2)).locale(.current)))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 8)
            .font(.title2)
    }

    @ViewBuilder
    private var closeButton: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            Button(role: .close) {
                dismiss()
            }
            .buttonStyle(.plain)
        } else {
            Button("", systemImage: "x.circle") {
                dismiss()
            }
        }
    }
    
    @ViewBuilder
    private var continueButton: some View {
        // We only want a fully valid state when we navigate forward
        // but NavigationLink is resolving the destination immediatelly
        // so we cannot use a nil value.
        // As a work-around, we can have the same kind of button
        // using an empty destination, since it is disabled anyway
        if let confirmedSelection = SelectedAmount(
            state: selectedAmount,
            currency: currencyType,
            isMonthly: paymentType.isMonthly
        ) {
            NavigationLink {
                PaymentSummary(selectedAmount: confirmedSelection)
            } label: {
                continueButtonText
            }
            .buttonStyle(.borderedProminent)
        } else {
            NavigationLink {
                EmptyView()
            } label: {
                continueButtonText
            }
            .buttonStyle(.borderedProminent)
            .disabled(true)
        }
    }
    
    @ViewBuilder
    private var continueButtonText: some View {
        Text(LocalString.payment_continue_button_title)
            .font(.body)
            .padding(.vertical, 8)
            .padding(.horizontal, 32)
    }
    
    @ViewBuilder
    private func errorMessage(isAbove: Bool) -> some View {
        Text(isAbove ? Payment.errorMessageAbove : Payment.errorMessageBelow)
            .font(.subheadline)
            .foregroundStyle(.red.opacity(0.75))
            .padding(.vertical, 16)
    }
}

private struct PredifinedButtonModifier: ViewModifier {
    let isSelected: Bool
    func body(content: Content) -> some View {
        if isSelected {
            content
                .buttonStyle(.borderedProminent)
        } else {
            content
                .buttonStyle(.bordered)
                .tint(.secondary)
        }
        
    }
}
