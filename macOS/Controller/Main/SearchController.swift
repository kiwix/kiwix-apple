//
//  SearchController.swift
//  Kiwix
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
        window?.standardWindowButton(NSWindow.ButtonType.closeButton)?.isHidden = true
        window?.standardWindowButton(NSWindow.ButtonType.miniaturizeButton)?.isHidden = true
        window?.standardWindowButton(NSWindow.ButtonType.fullScreenButton)?.isHidden = true
        window?.standardWindowButton(NSWindow.ButtonType.zoomButton)?.isHidden = true
    }
}

class SearchResultWindow: NSWindow {
    override var canBecomeKey: Bool {return false}
    override var canBecomeMain: Bool {return false}
}

class SearchController: NSViewController, ProcedureQueueDelegate, NSTableViewDataSource, NSTableViewDelegate {
    @IBOutlet weak var visiualEffect: NSVisualEffectView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var noResultLabel: NSTextField!
    @IBOutlet weak var tableView: NSTableView!
    
    let queue = ProcedureQueue()
    private(set) var results: [SearchResult] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureVisiualEffectView()
        queue.delegate = self
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        configureTrackingArea()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.makeFirstResponder(nil)
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
    
    func clearSearch() {
        results = []
        tableView.reloadData()
    }
    
    @IBAction func tableViewClicked(_ sender: NSTableView) {
        guard tableView.selectedRow >= 0 else {return}
        guard let mainController = NSApplication.shared.mainWindow?.windowController as? MainWindowController else {return}
        mainController.searchField.endSearch()
        guard let split = NSApplication.shared.mainWindow?.contentViewController as? NSSplitViewController,
            let controller = split.splitViewItems.last?.viewController as? WebViewController else {return}
        controller.load(url: results[tableView.selectedRow].url)
    }
    
    // MARK: - Mouse tracking
    
    func configureTrackingArea() {
        let options: NSTrackingArea.Options = [NSTrackingArea.Options.mouseMoved, NSTrackingArea.Options.activeAlways]
        let trackingArea = NSTrackingArea(rect: view.convert(tableView.frame, from: tableView.superview), options: options, owner: self, userInfo: nil)
        view.addTrackingArea(trackingArea)
    }
    
    override func mouseMoved(with event: NSEvent) {
        let point = tableView.convert(event.locationInWindow, from: nil)
        tableView.selectRowIndexes(IndexSet(integer: tableView.row(at: point)), byExtendingSelection: false)
    }

    // MARK: - ProcedureQueueDelegate
    
    func procedureQueue(_ queue: ProcedureQueue, willAddProcedure procedure: Procedure, context: Any?) -> ProcedureFuture? {
        guard queue.operationCount == 0 else {return nil}
        DispatchQueue.main.async {
            self.progressIndicator.startAnimation(nil)
            self.tableView.isHidden = true
            self.noResultLabel.isHidden = true
        }
        return nil
    }
    
    func procedureQueue(_ queue: ProcedureQueue, didFinishProcedure procedure: Procedure, withErrors errors: [Error]) {
        guard queue.operationCount == 0 else {return}
        DispatchQueue.main.async {
            self.progressIndicator.stopAnimation(nil)
            self.tableView.isHidden = self.results.count == 0
            self.noResultLabel.isHidden = !self.tableView.isHidden
            self.tableView.reloadData()
        }
    }
    
    // MARK: - NSTableViewDataSource & NSTableViewDelegate
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        if let row = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ResultRow"), owner: self) as? NSTableRowView {
            return row
        } else {
            let row = NSTableRowView()
            row.identifier = NSUserInterfaceItemIdentifier(rawValue: "ResultRow")
            return row
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let result = results[row]
        if result.hasSnippet {
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TitleSnippetResult"), owner: self) as! SearchTitleSnippetResultTableCellView
            cell.titleField.stringValue = result.title
            if let snippet = result.snippet {
                cell.snippetField.stringValue = snippet
            } else if let snippet = result.attributedSnippet {
                cell.snippetField.attributedStringValue = snippet
            } else {
                cell.snippetField.stringValue = ""
            }
            return cell
        } else {
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TitleResult"), owner: self) as! SearchTitleResultTableCellView
            cell.titleField.stringValue = result.title
            return cell
        }
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return results[row].hasSnippet ? 92 : 26
    }
}
