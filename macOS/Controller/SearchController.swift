//
//  SearchController.swift
//  macOS
//
//  Created by Chris Li on 10/13/19.
//  Copyright © 2019 Chris Li. All rights reserved.
//

import Cocoa

class SearchController: NSViewController, NSSearchFieldDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate, SearchQueueEvents {
    @IBOutlet weak var searchField: NSSearchField!
    @IBOutlet weak var outlineView: NSOutlineView!
    @IBOutlet weak var outlineViewContainer: NSScrollView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    private var searchFieldTopConstraint: NSLayoutConstraint?
    private let queue = SearchQueue()
    private var results = [SearchResult]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        queue.eventDelegate = self
    }
    
    override func updateViewConstraints() {
        if searchFieldTopConstraint == nil,
            let contentLayoutGuide = searchField.window?.contentLayoutGuide as? NSLayoutGuide {
            searchFieldTopConstraint = searchField.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor, constant: 10)
            searchFieldTopConstraint?.isActive = true
        }
        super.updateViewConstraints()
    }
    
    // MARK: - NSSearchFieldDelegate
    
    func controlTextDidChange(_ notification: Notification) {
        guard let searchField = notification.object as? NSSearchField,
            searchField == self.searchField else { return }
        queue.enqueue(searchText: searchField.stringValue, zimFileIDs: Set(ZimMultiReader.shared.ids))
    }
    
    // MARK: - NSOutlineViewDataSource
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return item == nil ? results.count : 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        return results[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return false
    }
    
    // MARK: - NSOutlineViewDelegate
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let item = item as? SearchResult else {return nil}
        let identifier = NSUserInterfaceItemIdentifier("Cell")
        let view = outlineView.makeView(withIdentifier: identifier, owner: self) as! NSTableCellView
        view.textField?.stringValue = item.title
        return view
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard let outlineView = notification.object as? NSOutlineView,
            let searchResult = outlineView.item(atRow: outlineView.selectedRow) as? SearchResult,
            let windowController = view.window?.windowController as? WindowController else {return}
        windowController.webViewController?.load(url: searchResult.url)
    }
    
    // MARK: - SearchQueueEvents
    
    func searchStarted() {
        outlineViewContainer.isHidden = true
        progressIndicator.isHidden = false
        progressIndicator.startAnimation(nil)
    }
    
    func searchFinished(searchText: String, results: [SearchResult]) {
        progressIndicator.stopAnimation(nil)
        progressIndicator.isHidden = true
        self.results = results
        outlineView.reloadData()
        outlineViewContainer.isHidden = false
    }
}
