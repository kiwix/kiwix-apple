//
//  Main.swift
//  macOS
//
//  Created by Chris Li on 9/28/19.
//  Copyright © 2019 Chris Li. All rights reserved.
//

import Cocoa
import WebKit

class Mainv2WindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    @IBAction func toggleSidebar(_ sender: NSToolbarItem) {
        guard let controller = window?.contentViewController as? NSSplitViewController? else {return}
        controller?.toggleSidebar(sender)
    }
    
    @IBAction override func newWindowForTab(_ sender: Any?) {
        let windowController = self.storyboard?.instantiateInitialController() as! Mainv2WindowController
        let newWindow = windowController.window!
        self.window?.addTabbedWindow(newWindow, ordered: .above)
    }
}

class WebViewController: NSViewController {
    @IBOutlet weak var webView: WKWebView!
}
