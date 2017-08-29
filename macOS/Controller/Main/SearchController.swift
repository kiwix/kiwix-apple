//
//  SearchController.swift
//  macOS
//
//  Created by Chris Li on 8/22/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import Cocoa
import ProcedureKit

class SearchResultWindowController: NSWindowController {
    override func windowDidLoad() {
        window?.titlebarAppearsTransparent = true
        window?.titleVisibility = .hidden
        window?.isOpaque = false
        window?.backgroundColor = .clear
        window?.standardWindowButton(NSWindowButton.closeButton)?.isHidden = true
        window?.standardWindowButton(NSWindowButton.miniaturizeButton)?.isHidden = true
        window?.standardWindowButton(NSWindowButton.fullScreenButton)?.isHidden = true
        window?.standardWindowButton(NSWindowButton.zoomButton)?.isHidden = true
    }
}

class SearchController: NSViewController, ProcedureQueueDelegate, NSTableViewDataSource, NSTableViewDelegate {
    @IBOutlet weak var visiualEffect: NSVisualEffectView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var tableView: NSTableView!
    
    let queue = ProcedureQueue()
    private(set) var results: [SearchResult] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureVisiualEffectView()
        queue.delegate = self
    }
    
    func configureVisiualEffectView() {
        visiualEffect.blendingMode = .behindWindow
        visiualEffect.state = .active
        if #available(OSX 10.11, *) {
            visiualEffect.material = .menu
        } else {
            visiualEffect.material = .light
        }
        visiualEffect.wantsLayer = true
        visiualEffect.layer?.cornerRadius = 4.0
    }
    
    func startSearch(searchTerm: String) {
        let procedure = SearchProcedure(term: searchTerm)
        procedure.add(observer: DidFinishObserver(didFinish: { [unowned self] (procedure, errors) in
            guard let procedure = procedure as? SearchProcedure else {return}
            OperationQueue.main.addOperation({
                self.results = procedure.results
            })
        }))
        queue.add(operation: procedure)
    }
    
    @IBAction func tableViewClicked(_ sender: NSTableView) {
        guard tableView.selectedRow >= 0 else {return}
        guard let split = view.window?.contentViewController as? NSSplitViewController,
            let controller = split.splitViewItems.last?.viewController as? WebViewController else {return}
        controller.load(url: results[tableView.selectedRow].url)
    }
    
    // MARK: - ProcedureQueueDelegate
    
    func procedureQueue(_ queue: ProcedureQueue, willAddProcedure procedure: Procedure, context: Any?) -> ProcedureFuture? {
        guard queue.operationCount == 0 else {return nil}
        DispatchQueue.main.async {
            self.progressIndicator.startAnimation(nil)
            self.tableView.isHidden = true
        }
        return nil
    }
    
    func procedureQueue(_ queue: ProcedureQueue, didFinishProcedure procedure: Procedure, withErrors errors: [Error]) {
        guard queue.operationCount == 0 else {return}
        DispatchQueue.main.async {
            self.progressIndicator.stopAnimation(nil)
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }
    
    // MARK: - NSTableViewDataSource & NSTableViewDelegate
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        if let row = tableView.make(withIdentifier: "ResultRow", owner: self) as? SearchResultTableRowView {
            return row
        } else {
            let row = SearchResultTableRowView()
            row.identifier = "ResultRow"
            return row
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.make(withIdentifier: "Result", owner: self) as! SearchResultTableCellView
        let result = results[row]
        cell.titleField.stringValue = result.title
        if let snippet = result.snippet {
            cell.snippetField.stringValue = snippet
        } else if let snippet = result.attributedSnippet {
            cell.snippetField.attributedStringValue = snippet
        } else {
            cell.snippetField.stringValue = ""
            cell.snippetField.attributedStringValue = NSAttributedString()
        }
        return cell
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return results[row].hasSnippet ? 92 : 26
    }
}



class SearchControllerOld: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    let searchMenu = NSMenu()
    var searchResults: [(id: String, title: String, path: String, snippet: NSAttributedString)] = []
    
    @IBOutlet weak var searchField: NSSearchField!
    @IBOutlet weak var tableView: NSTableView!
    @IBAction func searchFieldChanged(_ sender: NSSearchField) {
        guard let controller = view.window?.windowController as? MainWindowController else {return}
//        searchResults = ZimManager.shared.getSearchResults(searchTerm: sender.stringValue)
        tableView.reloadData()
    }
    @IBAction func tableViewClicked(_ sender: NSTableView) {
        guard tableView.selectedRow >= 0 else {return}
        let result = searchResults[tableView.selectedRow]
        guard let url = URL(bookID: result.id, contentPath: result.path) else {return}
        guard let split = view.window?.contentViewController as? NSSplitViewController,
            let controller = split.splitViewItems.last?.viewController as? WebViewController else {return}
        controller.load(url: url)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configSearchMenu()
    }
    
    func configSearchMenu() {
        let clear = NSMenuItem(title: "Clear", action: nil, keyEquivalent: "")
        clear.tag = Int(NSSearchFieldClearRecentsMenuItemTag)
        searchMenu.insertItem(clear, at: 0)
        
        searchMenu.insertItem(NSMenuItem.separator(), at: 0)
        
        let recents = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        recents.tag = Int(NSSearchFieldRecentsMenuItemTag)
        searchMenu.insertItem(recents, at: 0)
        
        let recentHeader = NSMenuItem(title: "Recent Search", action: nil, keyEquivalent: "")
        recentHeader.tag = Int(NSSearchFieldRecentsTitleMenuItemTag)
        searchMenu.insertItem(recentHeader, at: 0)
        
        let noRecent = NSMenuItem(title: "No Recent Search", action: nil, keyEquivalent: "")
        noRecent.tag = Int(NSSearchFieldNoRecentsMenuItemTag)
        searchMenu.insertItem(noRecent, at: 0)
        
        searchField.searchMenuTemplate = searchMenu
    }
    
    func clearSearch() {
        searchField.stringValue = ""
        searchResults = []
        tableView.reloadData()
    }
    
    // MARK: - NSTableViewDataSource
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        if let row = tableView.make(withIdentifier: "ResultRow", owner: self) as? SearchResultTableRowView {
            return row
        } else {
            let row = SearchResultTableRowView()
            row.identifier = "ResultRow"
            return row
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.make(withIdentifier: "Result", owner: self) as! SearchResultTableCellView
        cell.titleField.stringValue = searchResults[row].title
        cell.snippetField.attributedStringValue = searchResults[row].snippet
        return cell
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 92
    }
}
