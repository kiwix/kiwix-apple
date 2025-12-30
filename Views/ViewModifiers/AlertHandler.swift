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
    @State private var zimFileName: String = ""

    private let alert = NotificationCenter.default.publisher(for: .alert)

    func body(content: Content) -> some View {
        content.onReceive(alert) { notification in
            if let alertValue = notification.userInfo?["alert"] as? ActiveAlert {
                activeAlert = alertValue
                if case let .downloadFailed(_, zimFileID) = alertValue {
                    let zimFile = try? Database.shared.viewContext.fetch(ZimFile.fetchRequest(fileID: zimFileID)).first
                    zimFileName = zimFile?.name ?? "unknown"
                }
            }
        }
        .alert(alertText(), isPresented: Binding<Bool>.constant(activeAlert != nil)) {
            Button(LocalString.common_button_ok) {
                activeAlert = nil
            }
        }
    }
        
    private func alertText() -> String {
        switch activeAlert {
        case .articleFailedToLoad:
            return LocalString.alert_handler_alert_failed_title
        case let .downloadFailed(code, _):
            return LocalString.download_service_failed_description(withArgs: zimFileName, "\(code)")
        case let .downloadError(code, message):
            return LocalString.download_service_error_description(withArgs: "\(code)", message)
        case nil:
            return ""
        }
    }
}
