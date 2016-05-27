//
//  LocalBooksController.swift
//  Kiwix
//
//  Created by Chris Li on 5/17/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import Cocoa

class LocalBooksController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    @IBOutlet weak var tableView: NSTableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.setDataSource(self)
        tableView.setDelegate(self)
        
        tableView.tableColumns[1].headerCell.stringValue = "Name"
        tableView.tableColumns[2].headerCell.stringValue = "Language"
        tableView.tableColumns[3].headerCell.stringValue = "Size"
        tableView.tableColumns[4].headerCell.stringValue = "Article Count"
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.title = LocalizedStrings.ZimFiles
    }
    
    // MARK: - NSTableViewDataSource
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return 2
    }
    
    // MARK: - NSTableViewDelegate
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        switch tableColumn {
        case tableView.tableColumns[0]?:
            let cell = tableView.makeViewWithIdentifier("CheckBox", owner: nil) as? NSButton
            return cell
        case tableView.tableColumns[1]?:
            let cell = tableView.makeViewWithIdentifier("IconAndTitle", owner: nil) as? NSTableCellView
            cell?.textField?.stringValue = "\(row)"
            return cell
        case tableView.tableColumns[2]?:
            let cell = tableView.makeViewWithIdentifier("Language", owner: nil) as? NSTableCellView
            cell?.textField?.stringValue = "\(row)"
            return cell
        case tableView.tableColumns[3]?:
            let cell = tableView.makeViewWithIdentifier("Size", owner: nil) as? NSTableCellView
            cell?.textField?.stringValue = "\(row)"
            return cell
        case tableView.tableColumns[4]?:
            let cell = tableView.makeViewWithIdentifier("ArticleCount", owner: nil) as? NSTableCellView
            cell?.textField?.stringValue = "\(row)"
            return cell
        default:
            return nil
        }
    }
}