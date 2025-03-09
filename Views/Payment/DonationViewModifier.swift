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

#if os(iOS)
import SwiftUI
import Combine

struct DonationViewModifier: ViewModifier {
    
    enum DonationPopupState {
        case selection
        case selectedAmount(SelectedAmount)
        case thankYou
        case error
    }
    private let openDonations = NotificationCenter.default.publisher(for: .openDonations)
    private var amountSelected = PassthroughSubject<SelectedAmount?, Never>()
    @State private var showDonationPopUp: Bool = false
    @State private var donationPopUpState: DonationPopupState = .selection
    
    
    func body(content: Content) -> some View {
        content
            .onReceive(openDonations) { _ in
                showDonationPopUp = true
            }
            .sheet(isPresented: $showDonationPopUp, onDismiss: {
                let result = Payment.showResult()
                switch result {
                case .none:
                    // reset
                    donationPopUpState = .selection
                    return
                case .some(let finalResult):
                    Task {
                        // we need to close the sheet in order to dismiss ApplePay,
                        // and we need to re-open it again with a delay to show thank you state
                        // Swift UI cannot yet handle multiple sheets
                        try? await Task.sleep(for: .milliseconds(100))
                        await MainActor.run {
                            switch finalResult {
                            case .thankYou:
                                donationPopUpState = .thankYou
                            case .error:
                                donationPopUpState = .error
                            }
                            showDonationPopUp = true
                        }
                    }
                }
            }, content: {
                Group {
                    switch donationPopUpState {
                    case .selection:
                        PaymentForm(amountSelected: amountSelected)
                            .presentationDetents([.fraction(0.65)])
                    case .selectedAmount(let selectedAmount):
                        PaymentSummary(selectedAmount: selectedAmount, onComplete: {
                            showDonationPopUp = false
                        })
                        .presentationDetents([.fraction(0.65)])
                    case .thankYou:
                        PaymentResultPopUp(state: .thankYou)
                            .presentationDetents([.fraction(0.33)])
                    case .error:
                        PaymentResultPopUp(state: .error)
                            .presentationDetents([.fraction(0.33)])
                    }
                }
                .onReceive(amountSelected) { value in
                    if let amount = value {
                        donationPopUpState = .selectedAmount(amount)
                    } else {
                        donationPopUpState = .selection
                    }
                }
            })
    }
}
#endif
