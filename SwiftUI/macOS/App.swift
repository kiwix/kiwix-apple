//
//  App.swift
//  Kiwix
//
//  Created by Chris Li on 7/31/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

@main
struct Kiwix: App {
    init() {
        LibraryViewModel.reopen()
    }
    
    var body: some Scene {
        WindowGroup {
            #if os(macOS)
            RootView_macOS()
            #elseif os(iOS)
            RootView_iOS().ignoresSafeArea(.all)
            #endif
        }
    }
}