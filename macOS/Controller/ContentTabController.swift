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
        case welcome = "Welcome"
        case reader = "Reader"
    }
    
    var mode: Mode? {
        guard let identifier = tabViewItems[selectedTabViewItemIndex].identifier as? String else {return nil}
        return Mode(rawValue: identifier)
    }

    func setMode(_ mode: Mode) {
        tabView.selectTabViewItem(withIdentifier: mode.rawValue)
    }
}
