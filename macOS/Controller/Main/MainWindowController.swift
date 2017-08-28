//
//  MainController.swift
//  macOS
//
//  Created by Chris Li on 8/22/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import Cocoa
import SwiftyUserDefaults

class MainWindowController: NSWindowController, NSSearchFieldDelegate {
    @IBOutlet weak var titleTextField: NSTextField!
    @IBOutlet weak var loadingView: NSProgressIndicator!
    @IBOutlet weak var searchField: NSSearchField!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.titleVisibility = .hidden
    }
    
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
        
        openPanel.beginSheetModal(for: window!) { response in
            guard response == NSFileHandlingPanelOKButton else {return}
            let paths = openPanel.urls.map({$0.path})
            
            let bookmarks = paths.flatMap({try? URL(fileURLWithPath: $0).bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess], includingResourceValuesForKeys: nil, relativeTo: nil)})
            Defaults[.zimBookmarks] = bookmarks
            
            var isStale = false
            let urls = bookmarks.flatMap({try? URL(resolvingBookmarkData: $0, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)}).flatMap({$0})
            
            urls.forEach({_ = $0.startAccessingSecurityScopedResource()})
            print(urls)
            ZimManager.shared.removeAllBook();
            ZimManager.shared.addBooks(paths: paths)
            
            guard let split = self.contentViewController as? NSSplitViewController,
                let searchController = split.splitViewItems.first?.viewController as? SearchController,
                let webController = split.splitViewItems.last?.viewController as? WebViewController else {return}
            searchController.clearSearch()
            webController.loadMainPage()
        }
    }
    
    // MARK: - NSSearchFieldDelegate
    
    let searchResultWindowController = NSStoryboard(name: "Search", bundle: nil).instantiateInitialController() as! NSWindowController
    
    override func controlTextDidBeginEditing(_ obj: Notification) {
        guard let resultWindow = searchResultWindowController.window else {return}
        if !resultWindow.isVisible {
            showSearchResultWindow(searchField: searchField)
        }
    }
    
    override func controlTextDidEndEditing(_ obj: Notification) {
        guard let resultWindow = searchResultWindowController.window else {return}
        if resultWindow.isVisible {
            hideSearchResultWindow()
        }
    }
    
    func showSearchResultWindow(searchField: NSSearchField) {
        guard let parentWindow = searchField.window,
            let parentView = searchField.superview,
            let resultWindow = searchResultWindowController.window else {return}
        
        var frame = parentView.convert(searchField.frame, to: nil)
        frame = parentWindow.convertToScreen(frame)
        frame = NSRect(origin: frame.origin, size: CGSize(width: searchField.frame.width, height: 300))
        frame = frame.offsetBy(dx: 0, dy: -2)
        resultWindow.setFrame(frame, display: true)
        resultWindow.setFrameTopLeftPoint(frame.origin)
        parentWindow.addChildWindow(resultWindow, ordered: .above)
    }
    
    func hideSearchResultWindow() {
        guard let resultWindow = searchResultWindowController.window else {return}
        resultWindow.parent?.removeChildWindow(resultWindow)
        resultWindow.orderOut(nil)
    }
}

class WelcomeViewController: NSViewController {
    @IBAction func openBookButtonTapped(_ sender: NSButton) {
        
    }
}
