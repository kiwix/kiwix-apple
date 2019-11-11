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

class WindowController: NSWindowController, NSWindowDelegate, SearchFieldEvent {
    weak var tabManager: TabManagement?
    private var windowWillCloseObserver: NSObjectProtocol?
    
    let searchWindowController = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "Search") as! NSWindowController
    
    @IBOutlet weak var libraryButton: NSButton!
    @IBOutlet weak var searchField: SearchField!
    
    // MARK: controller shortcuts
    
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
    
    // MARK: overrides

    override func windowDidLoad() {
        super.windowDidLoad()
        
        searchField.eventDelegate = self
        windowWillCloseObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: self.window!,
            queue: OperationQueue.main,
            using: {[unowned self] (notification) in
                self.tabManager?.willCloseTab(controller: self)
                NotificationCenter.default.removeObserver(self.windowWillCloseObserver!)
        })
    }
    
    // MARK: IBActions
    
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
    
    // MARK: NSWindowDelegate
    
    func windowWillStartLiveResize(_ notification: Notification) {
        if searchField.searchStarted {
            hideSearchResultWindow()
        }
    }

    func windowDidEndLiveResize(_ notification: Notification) {
        let f = CGRect(x: searchField.frame.origin.x, y: searchField.frame.origin.y, width: 800, height: searchField.frame.height)
        searchField.frame = f
        if searchField.searchStarted {
            showSearchResultWindow()
        }
    }
    
    // MARK: NSSearchFieldDelegate
    
    func searchWillStart() {
        showSearchResultWindow()
    }
    
    func searchTextDidChange(searchText: String) {
    }
    
    func searchTextDidClear() {
//        guard let searchController = self.searchResultWindowController.contentViewController as? SearchResultController else {return}
//        searchController.clearSearch()
    }
    
    func searchWillEnd() {
        hideSearchResultWindow()
        window?.makeFirstResponder(nil)
//        searchField.alignment = .natural
    }
    
    // MARK: Search Window Management
    
    private var mouseDownEventMonitor: Any?
    
    private func showSearchResultWindow() {        
        guard let searchWindow = searchWindowController.window, !searchWindow.isVisible else {return}
        
        // calculate the frame of search window in main window's coordination system
        guard let mainWindow = searchField.window, let searchFieldSuperview = searchField.superview else {return}
        let searchFieldFrame = searchFieldSuperview.convert(searchField.frame, to: nil)
        let width = max(380, searchFieldFrame.width)
        let height = max(0.8 * width, 300)
        let origin: NSPoint = {
            if width == searchFieldFrame.width {
                return searchFieldFrame.origin
            } else {
                return NSPoint(x: (mainWindow.frame.width - width)/2, y: searchFieldFrame.origin.y)
            }
        }()
        let resultFrame = mainWindow.convertToScreen(
            NSRect(origin: origin, size: CGSize(width: width, height: height)).offsetBy(dx: 0, dy: -2)
        )
        
        // add search window as child window
        searchWindow.setFrame(resultFrame, display: true)
        searchWindow.setFrameTopLeftPoint(resultFrame.origin)
        mainWindow.addChildWindow(searchWindow, ordered: .above)
        
        let events: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        mouseDownEventMonitor = NSEvent.addLocalMonitorForEvents(matching: events) { (event) -> NSEvent? in
            if event.window == searchWindow {
                return event
            } else if event.window == mainWindow {
                let point = self.searchField.convert(event.locationInWindow, from: nil)
                let inSearchField = self.searchField.bounds.contains(point)
                if !inSearchField {
                    self.searchField.endSearch()
                }
                return event
            } else {
                self.searchField.endSearch()
                return event
            }
        }
    }
    
    private func hideSearchResultWindow() {
        guard let searchWindow = searchWindowController.window, searchWindow.isVisible else {return}
        searchWindow.parent?.removeChildWindow(searchWindow)
        searchWindow.orderOut(nil)
    }
}

// MARK: - View Controllers

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
