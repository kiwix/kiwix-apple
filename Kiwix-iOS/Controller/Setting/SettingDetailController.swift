//
//  SettingDetailController.swift
//  Kiwix
//
//  Created by Chris Li on 7/13/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import Operations

class SettingDetailController: UITableViewController {
    
    let switchControl = UISwitch()
    var page = SettingDetailControllerContentType.BackupLocalFiles

    override func viewDidLoad() {
        super.viewDidLoad()
        switch page {
        case .BackupLocalFiles:
            title = LocalizedStrings.backupLocalFiles
            switchControl.on = !(NSFileManager.getSkipBackupAttribute(item: NSFileManager.docDirURL) ?? false)
        case .SearchHistory:
            title = LocalizedStrings.searchHistory
        }
        
        switchControl.addTarget(self, action: #selector(SettingDetailController.switchValueChanged), forControlEvents: .ValueChanged)
    }
    
    func switchValueChanged() {
        if page == .BackupLocalFiles {
            NSFileManager.setSkipBackupAttribute(!switchControl.on, url: NSFileManager.docDirURL)
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch page {
        case .BackupLocalFiles:
            let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
            cell.textLabel?.text = LocalizedStrings.backupLocalFiles
            cell.accessoryView = switchControl
            return cell
        case .SearchHistory:
            let cell = tableView.dequeueReusableCellWithIdentifier("CenterTextCell", forIndexPath: indexPath)
            cell.textLabel?.text = LocalizedStrings.clearSearchHistory
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch page {
        case .BackupLocalFiles:
            return NSLocalizedString("When turned off, iOS will not backup zim files and index folders to iCloud or iTunes.",
                                     comment: "Setting: Backup local files comment") + "\n\n" +
                NSLocalizedString("Note: Large zim file collection can take up a lot of space in backup. You may want to turn this off if you use iCloud for backup.", comment: "Setting: Backup local files comment")
        case .SearchHistory:
            return nil
        }
    }
    
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        guard let title = tableView.cellForRowAtIndexPath(indexPath)?.textLabel?.text else {return}
        switch title {
        case LocalizedStrings.clearSearchHistory:
            Preference.recentSearchTerms = [String]()
            let controller = UIAlertController(title: NSLocalizedString("Cleared", comment: "Setting, search history cleared"),
                                               message: NSLocalizedString("Your search history has been cleared!", comment: "Setting, search history cleared"),
                                               preferredStyle: .Alert)
            let done = UIAlertAction(title: LocalizedStrings.done, style: .Default, handler: nil)
            controller.addAction(done)
            presentViewController(controller, animated: true, completion: nil)
        default:
            return
        }
    }

}

extension LocalizedStrings {
    static let clearSearchHistory = NSLocalizedString("Clear Search History", comment: "")
}

enum SettingDetailControllerContentType: String {
    case BackupLocalFiles, SearchHistory
}
