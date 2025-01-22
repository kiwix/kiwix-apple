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

struct AlertHandler: ViewModifier {
    @State private var activeAlert: ActiveAlert?

    private let alert = NotificationCenter.default.publisher(for: .alert)

    func body(content: Content) -> some View {
        content.onReceive(alert) { notification in
            guard let rawValue = notification.userInfo?["rawValue"] as? String else { return }
            activeAlert = ActiveAlert(rawValue: rawValue)
        }
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .articleFailedToLoad:
                return Alert(title: Text(LocalString.alert_handler_alert_failed_title))
            case .downloadFailed:
                return Alert(title: Text(LocalString.download_service_failed_description))
            }
        }
    }
}
