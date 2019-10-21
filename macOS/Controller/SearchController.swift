//
//  SearchController.swift
//  macOS
//
//  Created by Chris Li on 10/13/19.
//  Copyright © 2019 Chris Li. All rights reserved.
//

import Cocoa
import RealmSwift

class SearchController: NSViewController, NSSearchFieldDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate, SearchQueueEvents {
    @IBOutlet weak var searchField: NSSearchField!
    @IBOutlet weak var tabView: NSTabView!
    @IBOutlet weak var onDeviceOutlineView: NSOutlineView!
    @IBOutlet weak var resultsOutlineView: NSOutlineView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    private var searchFieldTopConstraint: NSLayoutConstraint?
    private let queue = SearchQueue()
    private var results = [SearchResult]()
    
    // MARK: - Database
    
    private let localZimFiles: Results<ZimFile>? = {
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            let predicate = NSPredicate(format: "stateRaw == %@", ZimFile.State.local.rawValue)
            return database.objects(ZimFile.self).filter(predicate)
        } catch { return nil }
    }()
    
    private let localIncludedInSearchZimFiles: Results<ZimFile>? = {
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            let predicate = NSPredicate(format: "stateRaw == %@ AND includeInSearch == true", ZimFile.State.local.rawValue)
            return database.objects(ZimFile.self).filter(predicate)
        } catch { return nil }
    }()
    
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
    
    // MARK: - SearchQueueEvents
    
    func searchStarted() {
        tabView.selectTabViewItem(withIdentifier: Tabs.InProgress.rawValue)
        progressIndicator.startAnimation(nil)
    }
    
    func searchFinished(searchText: String, results: [SearchResult]) {
        let tab = searchText.count > 0 ? Tabs.Results : Tabs.OnDevice
        self.results = results
        resultsOutlineView.reloadData()
        progressIndicator.stopAnimation(nil)
        tabView.selectTabViewItem(withIdentifier: tab.rawValue)
    }
    
    // MARK: - NSOutlineViewDataSource
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if outlineView == onDeviceOutlineView {
            return item == nil ? (localZimFiles?.count ?? 0) : 0
        } else if outlineView == resultsOutlineView {
            return item == nil ? results.count : 0
        } else {
            return 0
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if outlineView == onDeviceOutlineView {
            return localZimFiles?[index] ?? Object()
        } else if outlineView == resultsOutlineView {
            return results[index]
        } else {
            return Object()
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return false
    }
    
    // MARK: - NSOutlineViewDelegate
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        if outlineView == onDeviceOutlineView {
            guard let item = item as? ZimFile else {return nil}
            let identifier = NSUserInterfaceItemIdentifier("DataCell")
            let view = outlineView.makeView(withIdentifier: identifier, owner: self) as! NSTableCellView
            view.textField?.stringValue = item.title
            view.imageView?.image = NSImage(data: item.icon)
            return view
        } else if outlineView == resultsOutlineView {
            guard let item = item as? SearchResult else {return nil}
            let identifier = NSUserInterfaceItemIdentifier("DataCell")
            let view = outlineView.makeView(withIdentifier: identifier, owner: self) as! NSTableCellView
            view.textField?.stringValue = item.title
            do {
                let database = try Realm(configuration: Realm.defaultConfig)
                let zimFile = database.object(ofType: ZimFile.self, forPrimaryKey: item.zimFileID)
                view.imageView?.image = NSImage(data: zimFile?.icon ?? Data()) ?? #imageLiteral(resourceName: "GenericZimFile")
            } catch {}
            return view
        } else {
            return nil
        }
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard let outlineView = notification.object as? NSOutlineView else {return}
        if outlineView == onDeviceOutlineView {
            return
        } else if outlineView == resultsOutlineView {
            guard let searchResult = outlineView.item(atRow: outlineView.selectedRow) as? SearchResult,
                let windowController = view.window?.windowController as? WindowController else {return}
            windowController.webViewController?.load(url: searchResult.url)
        } else {
            return
        }
    }
}

private enum Tabs: String {
    case OnDevice = "OnDevice"
    case Results = "Results"
    case InProgress = "InProgress"
}
