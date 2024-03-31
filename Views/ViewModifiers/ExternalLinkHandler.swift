/*
 * This file is part of Kiwix for iOS & macOS.
 *
 * Kiwix is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * any later version.
 *
 * Kiwix is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Kiwix; If not, see https://www.gnu.org/licenses/.
*/

//
//  ExternalLinkHandler.swift
//  Kiwix
//
//  Created by Chris Li on 8/13/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import SwiftUI

import Defaults

struct ExternalLinkHandler: ViewModifier {
    @State private var isAlertPresented = false
    @State private var activeAlert: ActiveAlert?
    @State private var activeSheet: ActiveSheet?
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
        .alert("external_link_handler.alert.title".localized, 
               isPresented: $isAlertPresented,
               presenting: activeAlert) { alert in
            if case .ask(let url) = alert {
                Button("external_link_handler.alert.button.load.link".localized) {
                    load(url: url)
                    externalURL = nil // important to nil out, so the same link tapped will trigger onChange again
                }
                Button("common.button.cancel".localized, role: .cancel) {
                    externalURL = nil // important to nil out, so the same link tapped will trigger onChange again
                }
            }
        } message: { alert in
            switch alert {
            case .ask:
                Text("external_link_handler.alert.ask.description".localized)
            case .notLoading:
                Text("external_link_handler.alert.not_loading.description".localized)
            }
        }
        #if os(iOS)
        .sheet(item: $activeSheet) { sheet in
            if case .safari(let url) = sheet {
                SafariView(url: url)
            }
        }
        #endif
    }
    
    private func load(url: URL) {
        #if os(macOS)
        NSWorkspace.shared.open(url)
        #elseif os(iOS)
        activeSheet = .safari(url: url)
        #endif
    }
}
