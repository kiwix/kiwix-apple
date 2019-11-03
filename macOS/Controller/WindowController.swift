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

class WindowController: NSWindowController {
    weak var tabManager: TabManagement?
    private var windowWillCloseObserver: NSObjectProtocol?
    
    @IBOutlet weak var libraryButton: NSButton!
    
    // MARK: - controllers
    
    var navigationSplitViewController: NSSplitViewController? {
        get {
            let splitViewController = contentViewController as? NSSplitViewController
            return splitViewController?.splitViewItems.first?.viewController as? NSSplitViewController
        }
    }
    
    var contentTabController: ContentTabController? {
        get {
            let splitViewController = contentViewController as? NSSplitViewController
            return splitViewController?.splitViewItems.last?.viewController as? ContentTabController
        }
    }
    
    var zimFileManagerController: ZimFileManagerController? {
        get {
            return navigationSplitViewController?.splitViewItems.last?.viewController as? ZimFileManagerController
        }
    }
    
    var webViewController: WebViewController? {
        get {
            return contentTabController?.tabViewItems.last?.viewController as? WebViewController
        }
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        
        windowWillCloseObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: self.window!,
            queue: OperationQueue.main,
            using: {[unowned self] (notification) in
                self.tabManager?.willCloseTab(controller: self)
                NotificationCenter.default.removeObserver(self.windowWillCloseObserver!)
        })
    }
    
    @IBAction func toggleNavigation(_ sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 {
            webViewController?.goBack(nil)
        } else if sender.selectedSegment == 1 {
            webViewController?.goForward(nil)
        }
    }
    
    @IBAction func toggleSidebar(_ sender: NSToolbarItem) {
        guard let controller = window?.contentViewController as? NSSplitViewController? else {return}
        controller?.toggleSidebar(sender)
    }
    
    @IBAction func toggleLibrary(_ sender: NSButton) {
        switch sender.state {
        case .on:
            contentTabController?.tabView.selectFirstTabViewItem(nil)
        case .off:
            contentTabController?.tabView.selectLastTabViewItem(nil)
        default:
            break
        }
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
            (NSApplication.shared.delegate as? AppDelegate)?.openFile(urls: openPanel.urls)
        }
    }
    
    @IBAction override func newWindowForTab(_ sender: Any?) {
        tabManager?.createTab(window: window!)
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
//        splitView.setPosition(400, ofDividerAt: 0)
    }
}
