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
    
    private let externalLink = NotificationCenter.default.publisher(for: .externalLink)
    
    enum ActiveAlert {
        case ask(url: URL)
        case notLoading
    }
    
    enum ActiveSheet: Hashable, Identifiable {
        var id: Int { hashValue }
        case safari(url: URL)
    }
    
    func body(content: Content) -> some View {
        content.onReceive(externalLink) { notification in
            guard let url = notification.userInfo?["url"] as? URL else { return }
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
        .alert("External Link".localized, isPresented: $isAlertPresented, presenting: activeAlert) { alert in
            if case .ask(let url) = alert {
                Button("Load the link".localized) {
                    load(url: url)
                }
                Button("Cancel".localized, role: .cancel) { }
            }
        } message: { alert in
            switch alert {
            case .ask:
                Text("An external link is tapped, do you wish to load the link?".localized)
            case .notLoading:
                Text("An external link is tapped. However, your current setting does not allow it to be loaded.".localized)
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
