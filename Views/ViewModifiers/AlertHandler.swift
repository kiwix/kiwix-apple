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
                switch alertValue {
                case let .downloadErrorZIM(zimFileID, _):
                    let zimFile = try? Database.shared.viewContext.fetch(ZimFile.fetchRequest(fileID: zimFileID)).first
                    zimFileName = zimFile?.name ?? "unknown"
                default:
                    zimFileName = ""
                }
                activeAlert = alertValue
            }
        }
        .alert(alertTitle(), isPresented: Binding<Bool>.constant(activeAlert != nil), actions: {
            Button(LocalString.common_button_ok) {
                activeAlert = nil
            }
        }, message: {
            Text(alertMessage())
        })
    }
        
    private func alertTitle() -> String {
        switch activeAlert {
        case .articleFailedToLoad:
            LocalString.alert_handler_alert_failed_title
        case .downloadErrorGeneric:
            LocalString.download_service_error_general_title
        case .downloadErrorZIM:
            LocalString.download_service_error_zimfile_title(withArgs: zimFileName)
        case nil:
            ""
        }
    }
    
    private func alertMessage() -> String {
        switch activeAlert {
        case .articleFailedToLoad:
            LocalString.download_service_error_footer
        case let .downloadErrorGeneric(description):
            [description, LocalString.download_service_error_footer].joined(separator: "\n\n")
        case let .downloadErrorZIM(_, errorMessage):
            [errorMessage, LocalString.download_service_error_footer].joined(separator: "\n\n")
        case nil:
            ""
        }
    }
}
