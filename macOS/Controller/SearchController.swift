//
//  Search.swift
//  macOS
//
//  Created by Chris Li on 11/11/19.
//  Copyright © 2019 Chris Li. All rights reserved.
//

import Cocoa
import RealmSwift

class SearchWindow: NSWindow {
    override var canBecomeKey: Bool {return false}
    override var canBecomeMain: Bool {return false}
}


class SearchController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate, SearchQueueEvents {
    @IBOutlet weak var tabView: NSTabView!
    @IBOutlet weak var resultsOutlineView: NSOutlineView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    private let queue = SearchQueue()
    private(set) var searchText: String = ""
    private var results = [SearchResult]()
    weak var windowController: WindowController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        queue.eventDelegate = self
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        configureTrackingArea()
    }
    
    override func mouseMoved(with event: NSEvent) {
        let point = resultsOutlineView.convert(event.locationInWindow, from: view)
        let indexSet = IndexSet(integer: resultsOutlineView.row(at: point))
        resultsOutlineView.selectRowIndexes(indexSet, byExtendingSelection: false)
    }
    
    func configureTrackingArea() {
        let options: NSTrackingArea.Options = [.mouseMoved, .activeAlways]
        let trackingArea = NSTrackingArea(rect: view.bounds, options: options, owner: self, userInfo: nil)
        view.addTrackingArea(trackingArea)
    }
    
    func startSearch(searchText: String) {
        let zimFileIDs: Set<String> = Set(ZimMultiReader.shared.ids)
        queue.enqueue(searchText: searchText, zimFileIDs: zimFileIDs)
    }
    
    func clearSearch() {
        searchText = ""
        results = []
        resultsOutlineView.reloadData()
    }
    
    @IBAction func resultsOutlineViewClicked(_ sender: NSOutlineView) {
        guard let searchResult = sender.item(atRow: sender.selectedRow) as? SearchResult else {return}
        windowController?.contentTabController?.setMode(.reader)
        windowController?.webViewController?.load(url: searchResult.url)
        windowController?.searchField.endSearch()
    }
    
    // MARK: SearchQueueEvents
    
    func searchStarted() {
        tabView.selectTabViewItem(withIdentifier: Mode.inProgress.rawValue)
        progressIndicator.startAnimation(nil)
    }
    
    func searchFinished(searchText: String, results: [SearchResult]) {
        self.searchText = searchText
        self.results = results
        resultsOutlineView.reloadData()
        progressIndicator.stopAnimation(nil)
        if results.count > 0 {
            tabView.selectTabViewItem(withIdentifier: Mode.results.rawValue)
        } else {
            tabView.selectTabViewItem(withIdentifier: Mode.noResult.rawValue)
        }
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
        let identifier = NSUserInterfaceItemIdentifier("DataCell")
        let view = outlineView.makeView(withIdentifier: identifier, owner: self) as! NSTableCellView
        view.textField?.stringValue = item.title
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            let zimFile = database.object(ofType: ZimFile.self, forPrimaryKey: item.zimFileID)
            view.imageView?.image = NSImage(data: zimFile?.icon ?? Data()) ?? #imageLiteral(resourceName: "GenericZimFile")
        } catch {}
        return view
    }
}

private enum Mode: String {
    case results = "Results"
    case inProgress = "InProgress"
    case noResult = "NoResult"
}
