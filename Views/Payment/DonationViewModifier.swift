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
    
    enum DonationPopup: String, Identifiable {
        case inputForm
        case thankYou
        case error
        case errorAlreadyHasSubscription

        var id: String { rawValue }
    }
    
    private let openDonations = NotificationCenter.default.publisher(for: .openDonations)
    private let donationResult = NotificationCenter.default.publisher(for: .donationResult)
    @State private var donationPopup: DonationPopup?
    
    func body(content: Content) -> some View {
        content
            .onReceive(openDonations) { _ in
                donationPopup = .inputForm
            }
            .onReceive(donationResult) { notification in
                guard let finalResult = notification.userInfo?["result"] as? Payment.FinalResult else {
                    // reset
                    donationPopup = nil
                    return
                }
                process(finalResult)
            }
            .sheet(item: $donationPopup, onDismiss: {
                Log.Payment.debug("sheet onDismiss")
            },
            content: { item in
                Group {
                    switch item {
                    case .inputForm:
                        NavigationStack {
                            DonationForm()
                        }
                        .presentationDetents([.fraction(0.83)])
                    case .thankYou:
                        PaymentResultPopUp(state: .thankYou)
                            .presentationDetents([.fraction(0.43)])
                    case .error:
                        PaymentResultPopUp(state: .error)
                            .presentationDetents([.fraction(0.33)])
                    case .errorAlreadyHasSubscription:
                        PaymentResultPopUp(state: .errorAlreadyHasSubscription)
                            .presentationDetents([.fraction(0.33)])
                    }
                }
                // make sure payment sheet is not confusingly transparent on iPhone
                .presentationBackground(Color(.secondarySystemBackground))
            })
    }
    
    private func process(_ finalResult: Payment.FinalResult) {
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
            }
        }
        
    }
}
#endif
