//
//  SettingSearchHistoryTBVC.swift
//  Kiwix
//
//  Created by Chris Li on 7/14/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class SettingSearchHistoryTBVC: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Search History", comment: "Setting: Search History")
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        cell.textLabel?.text = NSLocalizedString("Clear Search History", comment: "Setting: Search History")
        return cell
    }
 
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let delete = UIAlertAction(title: LocalizedStrings.delete, style: .Destructive) { (action) in
            Preference.recentSearchTerms = []
            let ok = UIAlertAction(title: LocalizedStrings.ok, style: .Default, handler: nil)
            let alert = UIAlertController(title: NSLocalizedString("Your search history has been cleared.", comment: "Setting: Search History"), message: "", actions: [ok])
            self.presentViewController(alert, animated: true, completion: nil)
        }
        let cancel = UIAlertAction(title: LocalizedStrings.cancel, style: .Cancel, handler: nil)
        let alert = UIAlertController(title: NSLocalizedString("Are you sure?", comment: "Setting: Search History"),
                                      message: NSLocalizedString("This action is not recoverable.", comment: "Setting: Search History"),
                                      actions: [delete, cancel])
        presentViewController(alert, animated: true, completion: nil)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard section == tableView.numberOfSections - 1 else {return nil}
        return NSLocalizedString("Kiwix does not collect your search history data.", comment: "Setting: Search History")
    }
    
    override func tableView(tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        guard section == tableView.numberOfSections - 1 else {return}
        if let view = view as? UITableViewHeaderFooterView {
            view.textLabel?.textAlignment = .Center
        }
    }
}
