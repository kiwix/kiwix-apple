//
//  MainController.swift
//  macOS
//
//  Created by Chris Li on 8/22/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import Cocoa
import SwiftyUserDefaults

class MainWindowController: NSWindowController, NSWindowDelegate, NSSearchFieldDelegate {
    @IBOutlet weak var searchField: NSSearchField!
    let searchResultWindowController = NSStoryboard(name: "Search", bundle: nil).instantiateInitialController() as! NSWindowController
    private var shouldShowSearchWhenResizingFinished = false
    private var lostFocusObserver: Any?
    
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.titleVisibility = .hidden
        window?.delegate = self
    }
    
    func windowWillStartLiveResize(_ notification: Notification) {
        guard let resultWindow = searchResultWindowController.window else {return}
        if resultWindow.isVisible {
            hideSearchResultWindow()
            shouldShowSearchWhenResizingFinished = true
        }
    }
    
    func windowDidEndLiveResize(_ notification: Notification) {
        if shouldShowSearchWhenResizingFinished {
            showSearchResultWindow()
            shouldShowSearchWhenResizingFinished = false
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
    
    @IBAction func searchFieldTextDidChange(_ sender: NSSearchField) {
        guard let searchController = searchResultWindowController.contentViewController as? SearchController else {return}
        searchController.startSearch(searchTerm: sender.stringValue)
    }
    
    @IBAction func openBook(_ sender: NSMenuItem) {
        let openPanel = NSOpenPanel()
        openPanel.showsHiddenFiles = false
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        
        openPanel.beginSheetModal(for: window!) { response in
            guard response == NSFileHandlingPanelOKButton else {return}
            let paths = openPanel.urls.map({$0.path})
            
            let bookmarks = paths.flatMap({try? URL(fileURLWithPath: $0).bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess], includingResourceValuesForKeys: nil, relativeTo: nil)})
            Defaults[.zimBookmarks] = bookmarks
            
            var isStale = false
            let urls = bookmarks.flatMap({try? URL(resolvingBookmarkData: $0, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)}).flatMap({$0})
            ZimManager.shared.removeBooks();
            ZimManager.shared.addBook(urls: urls)
            
            guard let searchController = self.searchResultWindowController.contentViewController as? SearchController else {return}
//            searchController.clearSearch()
            guard let split = self.contentViewController as? NSSplitViewController,
                let webController = split.splitViewItems.last?.viewController as? WebViewController else {return}
            webController.loadMainPage()
        }
    }
    
    // MARK: - NSSearchFieldDelegate
    
    override func controlTextDidBeginEditing(_ obj: Notification) {
        guard let resultWindow = searchResultWindowController.window else {return}
        if !resultWindow.isVisible {
            showSearchResultWindow()
        }
    }
    
    override func controlTextDidEndEditing(_ obj: Notification) {
        guard let resultWindow = searchResultWindowController.window else {return}
        if resultWindow.isVisible {
            hideSearchResultWindow()
        }
    }
    
    func showSearchResultWindow() {
        guard let mainWindow = searchField.window,
            let parentView = searchField.superview,
            let resultWindow = searchResultWindowController.window else {return}
        let searchFieldFrame = parentView.convert(searchField.frame, to: nil)
        let width = max(380, searchFieldFrame.width)
        let height = max(0.6 * width, 300)
        let origin = width == searchFieldFrame.width ? searchFieldFrame.origin : NSPoint(x: (mainWindow.frame.width - width)/2, y: searchFieldFrame.origin.y)
        let resultFrame = mainWindow.convertToScreen(NSRect(origin: origin, size: CGSize(width: width, height: height)).offsetBy(dx: 0, dy: -2))
        resultWindow.setFrame(resultFrame, display: true)
        resultWindow.setFrameTopLeftPoint(resultFrame.origin)
        mainWindow.addChildWindow(resultWindow, ordered: .above)
        
//        NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { (event) -> NSEvent? in
//            if event.window == resultWindow {
//                return event
//            } else if event.window == mainWindow {
//                guard let contentView = mainWindow.contentView else {return event}
//                let point = contentView.convert(event.locationInWindow, from: nil)
//                let hitView = contentView.hitTest(point)
//                let editor = self.searchField.currentEditor()
//                if hitView != self.searchField && (editor != nil && hitView != editor) {
//                    self.hideSearchResultWindow()
//                    return nil
//                } else {
//                    return event
//                }
//            } else {
//                self.hideSearchResultWindow()
//                return event
//            }
//        }
//        
//        self.lostFocusObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSWindowDidResignKey, object: mainWindow, queue: nil) { (_) in
//            self.hideSearchResultWindow()
//        }
    }
    
    func hideSearchResultWindow() {
        guard let resultWindow = searchResultWindowController.window else {return}
        resultWindow.parent?.removeChildWindow(resultWindow)
        resultWindow.orderOut(nil)
        
        if let lostFocusObserver = lostFocusObserver {
            NotificationCenter.default.removeObserver(lostFocusObserver)
        }
        
    }
}

class WelcomeViewController: NSViewController {
    @IBAction func openBookButtonTapped(_ sender: NSButton) {
        
    }
}
