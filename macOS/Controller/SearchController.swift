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

class SearchController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {
    
    @IBOutlet weak var tabView: NSTabView!
    @IBOutlet weak var resultsOutlineView: NSOutlineView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    private let queue = SearchQueue()
    private(set) var searchText: String = ""
    private var results = [SearchResult]()
    weak var windowController: WindowController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        queue.cancelAllOperations()
        
        if searchText.count == 0 {
            tabView.selectTabViewItem(withIdentifier: Mode.noResult.rawValue)
        } else {
            tabView.selectTabViewItem(withIdentifier: Mode.inProgress.rawValue)
            progressIndicator.startAnimation(nil)
            
            let zimFileIDs: Set<String> = Set(ZimFileService.shared.ids)
            let operation = SearchOperation(searchText: searchText, zimFileIDs: zimFileIDs)
            operation.completionBlock = { [weak self] in
                guard !operation.isCancelled else {return}
                DispatchQueue.main.sync {
                    self?.searchText = searchText
                    self?.results = operation.results
                    self?.resultsOutlineView.reloadData()
                    self?.progressIndicator.stopAnimation(nil)
                    if operation.results.count > 0 {
                        self?.tabView.selectTabViewItem(withIdentifier: Mode.results.rawValue)
                    } else {
                        self?.tabView.selectTabViewItem(withIdentifier: Mode.noResult.rawValue)
                    }
                }
            }
            queue.addOperation(operation)
        }
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
        guard let item = item as? SearchResult else { return nil }
        if let snippet = item.snippet {
            let identifier = NSUserInterfaceItemIdentifier("SearchResultCellWithSnippet")
            let view = outlineView.makeView(withIdentifier: identifier, owner: self) as! SearchResultCell
            view.titleField.stringValue = item.title
            view.snippetField.attributedStringValue = snippet
            view.snippetField.maximumNumberOfLines = 4
            configureImage(cell: view, zimFileID: item.zimFileID)
            return view
        } else {
            let identifier = NSUserInterfaceItemIdentifier("SearchResultCell")
            let view = outlineView.makeView(withIdentifier: identifier, owner: self) as! SearchResultCell
            view.titleField.stringValue = item.title
            configureImage(cell: view, zimFileID: item.zimFileID)
            return view
        }
    }
    
    func configureImage(cell: NSTableCellView, zimFileID: String) {
        do {
            let database = try Realm()
            let zimFile = database.object(ofType: ZimFile.self, forPrimaryKey: zimFileID)
            cell.imageView?.image = NSImage(data: zimFile?.faviconData ?? Data()) ?? #imageLiteral(resourceName: "GenericZimFile")
        } catch {}
    }
}

private enum Mode: String {
    case results = "Results"
    case inProgress = "InProgress"
    case noResult = "NoResult"
}
