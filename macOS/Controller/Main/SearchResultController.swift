//
//  SearchController.swift
//  Kiwix
//
//  Created by Chris Li on 8/22/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import Cocoa

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

class SearchResultController: NSViewController, SearchQueueEvents, NSTableViewDataSource, NSTableViewDelegate {
    @IBOutlet weak var visiualEffect: NSVisualEffectView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var noResultLabel: NSTextField!
    @IBOutlet weak var tableView: NSTableView!
    
    private let queue = SearchQueue()
    private(set) var results: [SearchResult] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureVisiualEffectView()
        queue.eventDelegate = self
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
    
    func startSearch(searchText: String) {
        let zimFileIDs: Set<String> = Set(ZimMultiReader.shared.ids)
        queue.enqueue(searchText: searchText, zimFileIDs: zimFileIDs)
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
            let controller = split.splitViewItems.last?.viewController as? LegacyWebViewController else {return}
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

    // MARK: - SearchQueueEvents
    
    func searchStarted() {
        self.progressIndicator.startAnimation(nil)
        self.tableView.isHidden = true
        self.noResultLabel.isHidden = true

    }
    
    func searchFinished(searchText: String, results: [SearchResult]) {
        self.results = results
        self.progressIndicator.stopAnimation(nil)
        self.tableView.isHidden = self.results.count == 0
        self.noResultLabel.isHidden = !self.tableView.isHidden
        self.tableView.reloadData()
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
        if result.snippet != nil || result.attributedSnippet != nil {
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
        let hasSnippet = results[row].snippet != nil || results[row].attributedSnippet != nil
        return hasSnippet ? 92 : 26
    }
}
