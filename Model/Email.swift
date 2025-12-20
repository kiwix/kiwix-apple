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
#if os(macOS)
import AppKit
#endif

/// Prepares diagnostic email to be sent by the user
struct Email {
    
    let address: String = "app-diagnostic@kiwix.org"
    let subject: String = "Apple diagnostic report"
    let header: String = "Please describe your issue in English below:\(separator(count: 3))"
    let divider: String = "---LOGS---"
    let logs: String
    
    var body: String {
        [header, divider, logs].joined(separator: Self.separator())
    }
    
#if os(macOS)
    func create() {
        let sharingService = NSSharingService(named: NSSharingService.Name.composeEmail)
        sharingService?.recipients = [address]
        sharingService?.subject = subject
        let bodyItem = body.addingPercentEncoding(withAllowedCharacters: .alphanumerics)
        sharingService?.perform(withItems: [bodyItem as Any])
    }
#else
    func create() {
        var url = URL(string: "mailto:\(address)")!
        url.append(queryItems: [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ])
        UIApplication.shared.open(url)
    }
#endif
    
    static func separator(count: Int = 1) -> String {
        assert(count > 0)
#if os(macOS)
        let newLine: String = "<br>"
#else
        let newLine: String = "\r\n"
#endif
        return String(repeating: newLine, count: count)
    }
}
