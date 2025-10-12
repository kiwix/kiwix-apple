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
#if os(macOS)
import AppKit
#endif

/// Prepares diagnostic email to be sent by the user
struct Email {
    
    let address: String = "apple-diagnostic@kiwix.org"
    let subject: String = "Diagnostic report"
    let header: String = "Please describe your issue in English below:<br><br>"
    let divider: String = "---LOGS---"
    let logs: String
    static let separator: String = "<br>"
    
#if os(macOS)
    func create() {
        let sharingService = NSSharingService(named: NSSharingService.Name.composeEmail)
        sharingService?.recipients = [address]
        sharingService?.subject = subject
        
        let body = [header, divider, logs].joined(separator: Self.separator)
        let items: [Any] = [body]
        sharingService?.perform(withItems: items)
    }
#endif
    
}
