//
//  Focus.swift
//  Kiwix
//
//  Created by Chris Li on 5/27/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct SidebarDisplayModeKey: FocusedValueKey {
    typealias Value = Binding<SidebarDisplayMode>
}

extension FocusedValues {
    var sidebarDisplayMode: SidebarDisplayModeKey.Value? {
        get { self[SidebarDisplayModeKey.self] }
        set { self[SidebarDisplayModeKey.self] = newValue }
    }
}
