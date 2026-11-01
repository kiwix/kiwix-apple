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
                Task {
                    if !Brand.replaceDonation, await Payment.paymentButtonTypeAsync() != nil {
                        donationPopup = .inputForm
                    } else {
                        _ = await UIApplication.shared.open(Brand.donationURL)
                    }
                }
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
                        .modifier(DonationLayoutModifier())
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

private struct DonationLayoutModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 27.1, *) {
            GeometryReader { proxy in
                if isPartiallyFoldedPortrait(proxy) {
                    // don't allow the donation sheet to run through the fold (50%)
                    content.presentationDetents([.fraction(0.5)])
                } else if isFolded(proxy) {
                    // NOTE: we are redifining the `content` here
                    // to use large title
                    // and a full screen sheet
                    NavigationStack {
                        DonationForm(useInlineTitle: false)
                    }
                } else {
                    content.presentationDetents([.fraction(0.83)])
                }
            }
        } else {
            content.presentationDetents([.fraction(0.83)])
        }
    }
    
    /// iPhone DUO: detect a partially folded portrait mode
    /// - Parameter proxy: Geomertry reader
    /// - Returns: true when there's an active division, that is distintly wider than tall
    @available(anyAppleOS 27.1, *)
    private func isPartiallyFoldedPortrait(_ proxy: GeometryProxy) -> Bool {
        let divisions = proxy.reservedRegions(kind: .division)
        guard !divisions.isEmpty else { return false }
        return divisions.contains { div in
            div.frame.width > div.frame.height * 2
        }
    }
    
    /// iPhone DUO: detect full folded mode
    /// - Parameter proxy: Geometry reader
    /// - Returns: true when there's an asymetric leading / trailing inset larger than 50
    private func isFolded(_ proxy: GeometryProxy) -> Bool {
        let insets = proxy.safeAreaInsets
        switch (insets.leading, insets.trailing) {
        case let (0, trail):
            return trail > 50
        case let (lead, 0):
            return lead > 50
        default:
            return false
        }
    }
}

#endif
