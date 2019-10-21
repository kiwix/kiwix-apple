//
//  ContentController.swift
//  macOS
//
//  Created by Chris Li on 10/20/19.
//  Copyright © 2019 Chris Li. All rights reserved.
//

import Cocoa

class ContentTabController: NSTabViewController {
    enum Mode: String {
        case library = "Library"
        case reader = "Reader"
    }

    func setMode(_ mode: Mode) {
        tabView.selectTabViewItem(withIdentifier: mode.rawValue)
        if let windowController = view.window?.windowController as? WindowController {
            windowController.libraryButton.state = mode == .library ? .on : .off
        }
    }
}
