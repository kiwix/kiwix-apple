//
//  Window.swift
//  Kiwix
//
//  Created by Chris Li on 2/12/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import AppKit

class MainWindowController: NSWindowController {
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.titleVisibility = .hidden
    }
    
    
    @IBAction override func newWindowForTab(_ sender: Any?) {
        let windowController = storyboard?.instantiateInitialController() as! MainWindowController
        window?.addTabbedWindow(windowController.window!, ordered: .above)
        AppDelegate.add(controller: windowController)
        windowController.window?.orderFront(self.window)
        windowController.window?.makeKey()
    }
}

