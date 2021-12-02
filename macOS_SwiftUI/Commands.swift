//
//  Commands.swift
//  Kiwix
//
//  Created by Chris Li on 12/1/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

struct SidebarDisplayModeCommands : Commands {
    @FocusedBinding(\.sidebarDisplayMode) var displayMode: SidebarDisplayMode?
    
    var body: some Commands {
        CommandGroup(before: .sidebar) {
            Button("Show Search") { displayMode = .search }
                .keyboardShortcut("1")
                .disabled(displayMode == nil)
            Button("Show Bookmark") { displayMode = .bookmark }
                .keyboardShortcut("2")
                .disabled(displayMode == nil)
            Button("Show Table of Contrnt") { displayMode = .tableOfContent }
                .keyboardShortcut("3")
                .disabled(displayMode == nil)
            Button("Show Library") { displayMode = .library }
                .keyboardShortcut("4")
                .disabled(displayMode == nil)
            Divider()
        }
    }
}

struct SidebarDisplayModeKey: FocusedValueKey {
    typealias Value = Binding<SidebarDisplayMode>
}

extension FocusedValues {
    var sidebarDisplayMode: SidebarDisplayModeKey.Value? {
        get { self[SidebarDisplayModeKey.self] }
        set { self[SidebarDisplayModeKey.self] = newValue }
    }
}
