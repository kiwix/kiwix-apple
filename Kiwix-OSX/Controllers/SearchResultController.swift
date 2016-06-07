//
//  SearchResultController.swift
//  Kiwix
//
//  Created by Chris Li on 6/6/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import Cocoa

class SearchResultController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    @IBOutlet weak var tableView: NSTableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.setDataSource(self)
        tableView.setDelegate(self)
    }
    
    // MARK: - NSTableViewDataSource
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return 20
    }
    
    // MARK: - NSTableViewDelegate
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeViewWithIdentifier("Cell", owner: nil) as? NSTableCellView
        cell?.textField?.stringValue = "\(row)"
        return cell
    }
    
}
