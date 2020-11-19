//
//  Sidebar.swift
//  Kiwix
//
//  Created by Chris Li on 11/18/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import SwiftUI

enum SidebarDisplayMode {
    case hidden, bookmark, outline
}

@available(iOS 14.0, *)
struct SidebarDisplayModeEnvironmentKey: EnvironmentKey {
    static let defaultValue: SidebarDisplayMode = .hidden
}

@available(iOS 14.0, *)
extension EnvironmentValues {
    var sidebarDisplayMode: SidebarDisplayMode {
        get { self[SidebarDisplayModeEnvironmentKey] }
        set { self[SidebarDisplayModeEnvironmentKey] = newValue }
    }
}

@available(iOS 14.0, *)
struct SidebarView: View {
    var body: some View {
        Text("Sidebar!")
    }
}
