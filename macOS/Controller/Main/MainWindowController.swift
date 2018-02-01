//
//  MainController.swift
//  Kiwix
//
//  Created by Chris Li on 8/22/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import Cocoa
import SwiftyUserDefaults

class MainWindowController: NSWindowController, NSWindowDelegate, NSSearchFieldDelegate, SearchFieldDelegate {
    @IBOutlet weak var searchField: SearchField!
    let searchResultWindowController = NSStoryboard(name: NSStoryboard.Name(rawValue: "Search"), bundle: nil).instantiateInitialController() as! NSWindowController
    private var localMouseDownEventMonitor: Any?
    private var lostFocusObserver: Any?
    
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.titleVisibility = .hidden
        window?.delegate = self
        searchField.fieldDelegate = self
    }
    
    func windowWillStartLiveResize(_ notification: Notification) {
        if searchField.searchStarted {
            hideSearchResultWindow()
        }
    }

    func windowDidEndLiveResize(_ notification: Notification) {
        if searchField.searchStarted {
            showSearchResultWindow()
        }
    }
    
    func openBooks(paths: [String]) {
        let bookmarks = paths.flatMap({try? URL(fileURLWithPath: $0).bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess], includingResourceValuesForKeys: nil, relativeTo: nil)})
        Defaults[.zimBookmarks] = bookmarks
        
        var isStale = false
        let urls = bookmarks.flatMap({try? URL(resolvingBookmarkData: $0, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)}).flatMap({$0})
        ZimManager.shared.removeBooks();
        ZimManager.shared.addBook(urls: urls)
        
        guard let searchController = self.searchResultWindowController.contentViewController as? SearchResultController else {return}
        self.searchField.endSearch()
        self.searchField.searchTermCache = ""
        searchController.clearSearch()
        
        guard let split = self.contentViewController as? NSSplitViewController,
            let webController = split.splitViewItems.last?.viewController as? WebViewController else {return}
        if ZimManager.shared.getReaderIDs().count > 0 {
            webController.loadMainPage()
        } else {
            self.searchField.title = nil
            self.searchField.searchTermCache = ""
            self.searchTextDidClear()
            webController.webView.isHidden = true
            let alert = NSAlert()
            alert.messageText = "Cannot Open Book"
            alert.informativeText = "The file you selected is not a valid zim file."
            alert.addButton(withTitle: "Ok")
            alert.runModal()
        }
    }
    
    // MARK: - Actions
    
    @IBAction func mainPageButtonTapped(_ sender: NSToolbarItem) {
        guard let split = contentViewController as? NSSplitViewController,
            let controller = split.splitViewItems.last?.viewController as? WebViewController else {return}
        controller.loadMainPage()
    }
    
    @IBAction func backForwardControlClicked(_ sender: NSSegmentedControl) {
        guard let split = contentViewController as? NSSplitViewController,
            let controller = split.splitViewItems.last?.viewController as? WebViewController else {return}
        if sender.selectedSegment == 0 {
            controller.webView.goBack()
        } else if sender.selectedSegment == 1 {
            controller.webView.goForward()
        }
    }
    
    @IBAction func openBook(_ sender: NSMenuItem) {
        let openPanel = NSOpenPanel()
        openPanel.showsHiddenFiles = false
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["zim", "zimaa"]
        
        openPanel.beginSheetModal(for: window!) { response in
            guard response.rawValue == NSFileHandlingPanelOKButton else {return}
            let paths = openPanel.urls.map({$0.path})
            self.openBooks(paths: paths)
        }
    }
    
    // MARK: - NSSearchFieldDelegate
    
    func searchWillStart() {
        showSearchResultWindow()
    }
    
    func searchTextDidClear() {
        guard let searchController = self.searchResultWindowController.contentViewController as? SearchResultController else {return}
        searchController.clearSearch()
    }
    
    func searchWillEnd() {
        hideSearchResultWindow()
        window?.makeFirstResponder(nil)
    }
    
    @IBAction func searchFieldTextDidChange(_ sender: NSSearchField) {
        searchField.searchTermCache = sender.stringValue
        guard let searchController = searchResultWindowController.contentViewController as? SearchResultController else {return}
        searchController.startSearch(searchTerm: sender.stringValue)
    }
    
    private func showSearchResultWindow() {
        guard let resultWindow = searchResultWindowController.window, !resultWindow.isVisible else {return}
        guard let mainWindow = searchField.window,
            let parentView = searchField.superview else {return}
        let searchFieldFrame = parentView.convert(searchField.frame, to: nil)
        let width = max(380, searchFieldFrame.width)
        let height = max(0.75 * width, 300)
        let origin = width == searchFieldFrame.width ? searchFieldFrame.origin : NSPoint(x: (mainWindow.frame.width - width)/2, y: searchFieldFrame.origin.y)
        let resultFrame = mainWindow.convertToScreen(NSRect(origin: origin, size: CGSize(width: width, height: height)).offsetBy(dx: 0, dy: -2))
        resultWindow.setFrame(resultFrame, display: true)
        resultWindow.setFrameTopLeftPoint(resultFrame.origin)
        mainWindow.addChildWindow(resultWindow, ordered: .above)
        
        localMouseDownEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [NSEvent.EventTypeMask.leftMouseDown, NSEvent.EventTypeMask.rightMouseDown, NSEvent.EventTypeMask.otherMouseDown]) { (event) -> NSEvent? in
            if event.window == resultWindow {
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

        lostFocusObserver = NotificationCenter.default.addObserver(forName: NSWindow.didResignKeyNotification, object: mainWindow, queue: nil) { (_) in
            self.searchField.endSearch()
        }
    }
    
    private func hideSearchResultWindow() {
        guard let resultWindow = searchResultWindowController.window, resultWindow.isVisible else {return}
        resultWindow.parent?.removeChildWindow(resultWindow)
        resultWindow.orderOut(nil)
        
        if let monitor = localMouseDownEventMonitor {
            NSEvent.removeMonitor(monitor)
            localMouseDownEventMonitor = nil
        }
        
        if let observer = lostFocusObserver {
            NotificationCenter.default.removeObserver(observer)
            lostFocusObserver = nil
        }
    }
}
