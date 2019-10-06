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
//            self.openZimFiles(paths: paths)
        }
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

class ZimFileManagerViewController: NSViewController, NSOutlineViewDelegate, NSOutlineViewDataSource {
    @IBOutlet weak var outlineView: NSOutlineView!
    private var items = [OutlineItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        items = [
            OutlineItem(name: "Recent Files", children: [
                OutlineItem(name: "a"),
                OutlineItem(name: "b"),
                OutlineItem(name: "c")
            ])
        ]
        outlineView.reloadData()
        outlineView.expandItem(nil, expandChildren: true)
    }
    var recentZimFiles = ["a", "b", "c"]
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let item = item as? OutlineItem {
            return item.children.count
        } else {
            return items.count
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let item = item as? OutlineItem {
            return item.children[index]
        } else {
            return items[index]
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let item = item as? OutlineItem else {return false}
        return item.children.count > 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let item = item as? OutlineItem else {return nil}
        let identifier = NSUserInterfaceItemIdentifier(item.children.count > 0 ? "HeaderCell" : "DataCell")
        let view = outlineView.makeView(withIdentifier: identifier, owner: self) as! NSTableCellView
        view.textField?.stringValue = item.name
        return view
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldShowOutlineCellForItem item: Any) -> Bool {
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        guard let item = item as? OutlineItem else {return false}
        return item.children.count == 0
    }
}

private class OutlineItem {
    let name: String
    let children: [OutlineItem]
    
    init(name: String, children: [OutlineItem] = []) {
        self.name = name
        self.children = children
    }
}
