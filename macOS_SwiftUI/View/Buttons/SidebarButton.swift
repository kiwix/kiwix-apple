//
//  SidebarButton.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 2/13/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct SidebarButton: View {
    var body: some View {
        Button {
            guard let responder = NSApp.keyWindow?.firstResponder else { return }
            responder.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
        } label: {
            Image(systemName: "sidebar.leading")
        }
    }
}
