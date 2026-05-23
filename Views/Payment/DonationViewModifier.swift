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
    
    enum DonationPopup: Identifiable {
        case selection
        case selectedAmount(SelectedAmount)
        case thankYou
        case error
        case errorAlreadyHasSubscription
        
        var id: String {
            switch self {
            case .selection: "selection"
            case .selectedAmount: "selectedAmount"
            case .thankYou: "thankYou"
            case .error: "error"
            case .errorAlreadyHasSubscription: "errorAlreadyHasSubscription"
            }
        }
    }
    
    private let openDonations = NotificationCenter.default.publisher(for: .openDonations)
    private let donationResult = NotificationCenter.default.publisher(for: .donationResult)
    private var amountSelected = PassthroughSubject<SelectedAmount?, Never>()
    @State private var donationPopup: DonationPopup?
    private let popupSize: PresentationDetent = if Device.current == .iPad { .fraction(0.83) } else { .fraction(0.65) }
    
    func body(content: Content) -> some View {
        content
            .onReceive(openDonations) { _ in
                donationPopup = .selection
            }
            .onReceive(donationResult) { notification in
                guard let finalResult = notification.userInfo?["result"] as? Payment.FinalResult else {
                    // reset
                    donationPopup = nil
                    return
                }
                if finalResult != .dismiss {
                    process(finalResult)
                }
            }
            .sheet(item: $donationPopup, onDismiss: {
                Log.Payment.debug("sheet onDismiss")
            },
            content: { item in
                Group {
                    switch item {
                    case .selection:
                        PaymentForm(amountSelected: amountSelected)
                            .presentationDetents([popupSize])
                    case .selectedAmount(let selectedAmount):
                        PaymentSummary(selectedAmount: selectedAmount)
                        .presentationDetents([popupSize])
                    case .thankYou:
                        PaymentResultPopUp(state: .thankYou)
                            .presentationDetents([.fraction(0.33)])
                    case .error:
                        PaymentResultPopUp(state: .error)
                            .presentationDetents([.fraction(0.33)])
                    case .errorAlreadyHasSubscription:
                        PaymentResultPopUp(state: .errorAlreadyHasSubscription)
                            .presentationDetents([.fraction(0.33)])
                    }
                }
                .onReceive(amountSelected) { value in
                    if let amount = value {
                        donationPopup = .selectedAmount(amount)
                    } else {
                        donationPopup = .selection
                    }
                }
                // make sure payment sheet is not confusingly transparent on iPhone
                .presentationBackground(Color(.secondarySystemBackground))
            })
    }
    
    private func process(_ finalResult: Payment.FinalResult) {
        guard finalResult != .dismiss else { return }
        Log.Payment.debug("received finalResult: \(finalResult.rawValue)")
        Task(priority: .utility) {
            // we need to wait until ApplePay dismisses properly,
            // and we need to re-open the sheet again with a delay to show thank you / error state
            // Swift UI cannot yet handle multiple sheets
            try? await Task.sleep(for: .milliseconds(2000))
            switch finalResult {
            case .thankYou:
                donationPopup = .thankYou
            case .error:
                donationPopup = .error
            case .errorAlreadyHasSubscription:
                donationPopup = .errorAlreadyHasSubscription
            case .dismiss:
                break // do nothing
            }
        }
        
    }
}
#endif
