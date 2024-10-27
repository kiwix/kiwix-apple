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

import Foundation
import Combine

protocol BrowserViewModelClearable {
    @MainActor var zimFileId: UUID? { get }
    @MainActor func clear() async
}

#if os(macOS)
/// macOS only! When unlinking / deleting the ZIM file,
/// and .closeZIM was dispatched via NotificationCenter
/// instructs the BrowserViewModel to clear
///
@MainActor
struct BrowserClearViewModel {

    /// - Parameters:
    ///   - ids: set of ZIM file ids that are still in use
    ///   - forBrowser: BrowserViewModel instance
    func recievedClearZimFile(notification: Notification, forBrowser browser: BrowserViewModelClearable) {
        guard let zimIdToClose = notification.userInfo?["zimId"] as? UUID,
              browser.zimFileId == zimIdToClose else { return }
        // Using Task to avoid:
        // Publishing changes from within view updates is not allowed...
        Task { @MainActor in
            await browser.clear()
        }
    }
}
#endif
