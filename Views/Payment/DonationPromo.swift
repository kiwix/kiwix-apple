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
import Defaults
import Foundation

@MainActor
final class DonationPromo {
    private static let twelveMonths: TimeInterval = 31_536_000 // seconds from 60*60*24*365
    static let shared = DonationPromo()
    
    private init() {
        Task {
            await subscribe()
        }
    }
    
    func showCell() -> Bool {
        guard Brand.showDonations else { return false }
        if let lastTime = Defaults[.lastDonationTime], lastTime.timeIntervalSinceNow < Self.twelveMonths {
            return false
        }
        return true
    }
    
    private func subscribe() async {
        for await notif in NotificationCenter.default.notifications(named: .donationResult) {
            if let result = notif.userInfo?["result"] as? Payment.FinalResult {
                switch result {
                case .thankYou, .errorAlreadyHasSubscription:
                    storeDonationTime()
                case .error:
                    break
                }
            }
        }
    }
    
    private func storeDonationTime() {
        Defaults[.lastDonationTime] = Date()
    }
}
#endif
