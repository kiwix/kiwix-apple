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

import Defaults

struct ExternalLinkHandler: ViewModifier {
    @State private var isAlertPresented = false
    @State private var activeAlert: ActiveAlert?
    @Binding var externalURL: URL?

    enum ActiveAlert {
        case ask(url: URL)
        case notLoading
    }

    enum ActiveSheet: Hashable, Identifiable {
        var id: Int { hashValue }
        case safari(url: URL)
    }

    func body(content: Content) -> some View {
        content.onChange(of: externalURL) { url in
            guard let url else { return }
            switch Defaults[.externalLinkLoadingPolicy] {
            case .alwaysAsk:
                isAlertPresented = true
                activeAlert = .ask(url: url)
            case .alwaysLoad:
                load(url: url)
            case .neverLoad:
                isAlertPresented = true
                activeAlert = .notLoading
            }
        }
        .alert(LocalString.external_link_handler_alert_title,
               isPresented: $isAlertPresented,
               presenting: activeAlert) { alert in
            if case .ask(let url) = alert {
                Button(LocalString.external_link_handler_alert_button_load_link) {
                    load(url: url)
                    externalURL = nil // important to nil out, so the same link tapped will trigger onChange again
                }
                Button(LocalString.common_button_cancel, role: .cancel) {
                    externalURL = nil // important to nil out, so the same link tapped will trigger onChange again
                }
            }
        } message: { alert in
            switch alert {
            case .ask:
                Text(LocalString.external_link_handler_alert_ask_description)
            case .notLoading:
                Text(LocalString.external_link_handler_alert_not_loading_description)
            }
        }
    }

    private func load(url: URL) {
        #if os(macOS)
        NSWorkspace.shared.open(url)
        #elseif os(iOS)
        UIApplication.shared.open(url)
        #endif
    }
}
