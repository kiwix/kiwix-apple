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
            if #available(macOS 13.0, iOS 16.0, *) {
                RootView_SwiftUI4()
            } else {
                #if os(macOS)
                RootView_macOS()
                #elseif os(iOS)
                RootView_iOS().ignoresSafeArea(.all)
                #endif
            }
        }
    }
}
