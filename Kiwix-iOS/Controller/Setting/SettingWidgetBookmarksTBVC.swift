//
//  SettingWidgetBookmarksTBVC.swift
//  Kiwix
//
//  Created by Chris Li on 7/26/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class SettingWidgetBookmarksTBVC: UITableViewController {
    private var rowCount = 1 // widget row count
    
    let options = [NSLocalizedString("One Row", comment: "Setting: Bookmark Widget"),
                   NSLocalizedString("Two Rows", comment: "Setting: Bookmark Widget"),
                   NSLocalizedString("Three Rows", comment: "Setting: Bookmark Widget")]
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        title = LocalizedStrings.bookmarks
        if let defaults = NSUserDefaults(suiteName: "group.kiwix") {
            rowCount = max(1, min(defaults.integerForKey("BookmarkWidgetRowCount"), 3))
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        let defaults = NSUserDefaults(suiteName: "group.kiwix")
        defaults?.setInteger(rowCount ?? 1, forKey: "BookmarkWidgetRowCount")
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        cell.textLabel?.text = options[indexPath.row]
        cell.accessoryType = indexPath.row == (rowCount - 1) ? .Checkmark : .None
        return cell
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return NSLocalizedString("Set the maximum number of rows displayed in Bookmarks Today Widget.", comment: "Setting: Bookmark Widget")
    }
    
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let oldIndexPath = NSIndexPath(forItem: rowCount - 1, inSection: 0)
        guard let oldCell = tableView.cellForRowAtIndexPath(oldIndexPath),
            let newCell = tableView.cellForRowAtIndexPath(indexPath) else {return}
        oldCell.accessoryType = .None
        newCell.accessoryType = .Checkmark
        rowCount = indexPath.row + 1
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    override func tableView(tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        guard section == 0 else {return}
        guard let view = view as? UITableViewHeaderFooterView else {return}
        view.textLabel?.textAlignment = .Center
    }
}