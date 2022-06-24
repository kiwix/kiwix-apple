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

struct ReaderViewModelKey: FocusedValueKey {
    typealias Value = ReaderViewModel
}


extension FocusedValues {
    var sidebarDisplayMode: SidebarDisplayModeKey.Value? {
        get { self[SidebarDisplayModeKey.self] }
        set { self[SidebarDisplayModeKey.self] = newValue }
    }
    
    var readerViewModel: ReaderViewModelKey.Value? {
        get { self[ReaderViewModelKey.self] }
        set { self[ReaderViewModelKey.self] = newValue }
    }
}
