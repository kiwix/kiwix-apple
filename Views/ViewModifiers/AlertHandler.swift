//
//  AlertHandler.swift
//  Kiwix
//
//  Created by Chris Li on 8/14/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

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
                return Alert(title: Text("Unable to load the article requested."))
            }
        }
    }
}
