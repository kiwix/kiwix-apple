//
//  Main.swift
//  macOS
//
//  Created by Chris Li on 9/28/19.
//  Copyright © 2019 Chris Li. All rights reserved.
//

import Cocoa
import WebKit
import SwiftyUserDefaults
import SwiftUI

class Mainv2WindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    @IBAction func toggleSidebar(_ sender: NSToolbarItem) {
        guard let controller = window?.contentViewController as? NSSplitViewController? else {return}
        controller?.toggleSidebar(sender)
    }
    
    @IBAction func openFile(_ sender: NSToolbarItem) {
        let openPanel = NSOpenPanel()
        openPanel.showsHiddenFiles = false
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["zim"]
        
        openPanel.beginSheetModal(for: window!) { response in
            guard response.rawValue == NSFileHandlingPanelOKButton else {return}
            let paths = openPanel.urls.map({$0.path})
            self.openZimFiles(paths: paths)
        }
    }
    
    @IBAction override func newWindowForTab(_ sender: Any?) {
        let windowController = self.storyboard?.instantiateInitialController() as! Mainv2WindowController
        let newWindow = windowController.window!
        self.window?.addTabbedWindow(newWindow, ordered: .above)
    }
    
    func openZimFiles(paths: [String]) {
        let zimFileBookmarks = paths.compactMap { (path) -> Data? in
            return try? URL(fileURLWithPath: path).bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                                                              includingResourceValuesForKeys: nil,
                                                              relativeTo: nil)
        }
        Defaults[.zimFileBookmarks] += zimFileBookmarks
        
        if let contentViewController = contentViewController as? NSSplitViewController,
            let navigationSplitViewController = contentViewController.splitViewItems[0].viewController as? NSSplitViewController,
            let manager = navigationSplitViewController.splitViewItems[1].viewController as? ZimFileManagerController {
            manager.reloadData()
        }
    }
}

class WebViewController: NSViewController {
    @IBOutlet weak var webView: WKWebView!
}


