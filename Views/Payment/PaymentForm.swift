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

struct PaymentForm: View {
    let amountSelected: PassthroughSubject<SelectedAmount?, Never>
    @State var isMonthly: Bool = false
    @Environment(\.dismiss) var dismiss
    #if os(macOS)
    @EnvironmentObject var formReset: FormReset
    #endif

    init(amountSelected: PassthroughSubject<SelectedAmount?, Never>) {
        self.amountSelected = amountSelected
    }

    private func reset() {
        isMonthly = false
    }

    var body: some View {
        #if os(iOS)
        HStack {
            Spacer()
            Text("payment.donate.title".localized)
                .font(.title)
                .padding()
            Spacer()
        }
        .overlay(alignment: .topTrailing) {
            Button("", systemImage: "x.circle.fill") {
                dismiss()
            }
            .font(.title)
            .foregroundStyle(.tertiary)
            .padding()
        }
        #endif

        VStack {
            Picker("", selection: $isMonthly) {
                Label("payment.selection.option.one_time".localized, systemImage: "heart.circle").tag(false)
                Label("payment.selection.option.monthly".localized, systemImage: "arrow.clockwise.heart").tag(true)
            }.pickerStyle(.segmented)
                .padding([.leading, .trailing, .bottom])

            ListOfAmounts(amountSelected: amountSelected, isMonthly: $isMonthly)
        }
        #if os(macOS)
        .padding()
        .navigationTitle("payment.donate.title".localized)
        .onReceive(formReset.objectWillChange) { _ in
            reset()
        }
        #endif

    }
}

#Preview {
    PaymentForm(amountSelected: PassthroughSubject<SelectedAmount?, Never>())
}

struct SelectedAmount {
    let value: Double
    let currency: String
    let isMonthly: Bool
}

struct AmountOption: Identifiable {
    // stabelise the scroll, if we have the same amount
    // for both one-time and monthly and we switch in-between them
    let id = UUID()
    let value: Double
    let isAverage: Bool

    init(value: Double, isAverage: Bool = false) {
        self.value = value
        self.isAverage = isAverage
    }
}

final class FormReset: ObservableObject {
    func reset() {
        objectWillChange.send()
    }
}
