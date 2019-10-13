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
import RealmSwift

class Mainv2WindowController: NSWindowController {
    let queue = OperationQueue()

    override func windowDidLoad() {
        super.windowDidLoad()
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
            guard response == .OK, openPanel.urls.count > 0 else {return}
            self.openZimFiles(urls: openPanel.urls)
        }
    }
    
    @IBAction override func newWindowForTab(_ sender: Any?) {
        let windowController = self.storyboard?.instantiateInitialController() as! Mainv2WindowController
        let newWindow = windowController.window!
        self.window?.addTabbedWindow(newWindow, ordered: .above)
    }
    
    func openZimFiles(urls: [URL]) {
        let operation = LibraryScanOperation(urls: urls)
        queue.addOperation(operation)
    }
    
    var zimFileManagerController: ZimFileManagerController? {
        get {
            let splitViewController = contentViewController as? NSSplitViewController
            let leftSplitViewController = splitViewController?.splitViewItems.first?.viewController as? NSSplitViewController
            return leftSplitViewController?.splitViewItems.last?.viewController as? ZimFileManagerController
        }
    }
    
    var webViewController: WebViewController? {
        get {
            let splitViewController = contentViewController as? NSSplitViewController
            return splitViewController?.splitViewItems.last?.viewController as? WebViewController
        }
    }
}

class MainSplitViewController: NSSplitViewController {
    override func viewWillAppear() {
        super.viewWillAppear()
        splitView.setPosition(300, ofDividerAt: 0)
    }
}

class NavigationSplitViewController: NSSplitViewController {
    override func viewWillAppear() {
        super.viewWillAppear()
        splitView.setPosition(400, ofDividerAt: 0)
    }
}
