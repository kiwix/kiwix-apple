//
//  LibraryBackupTBVC.swift
//  Kiwix
//
//  Created by Chris Li on 6/14/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class LibraryBackupTBVC: UITableViewController {

    let toggle = UISwitch()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Backup", comment: "Setting: Backup local files title")
        toggle.addTarget(self, action: #selector(LibraryBackupTBVC.switcherValueChanged(_:)), forControlEvents: .ValueChanged)
        toggle.on = !(FileManager.getSkipBackupAttribute(item: NSFileManager.docDirURL) ?? false)
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
        
        cell.textLabel?.text = LocalizedStrings.libraryBackup
        cell.accessoryView = toggle
        
        return cell
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return NSLocalizedString("When turned off, iOS will not backup zim files and index folders to iCloud or iTunes.",
                                 comment: "Setting: Backup local files comment") + "\n\n" +
               NSLocalizedString("Note: Large zim file collection can take up a lot of space in backup. You may want to turn this off if you use iCloud for backup.", comment: "Setting: Backup local files comment")
    }
    
    // MARK: - Actions
    
    func switcherValueChanged(switcher: UISwitch) {
        guard switcher == toggle else {return}
        FileManager.setSkipBackupAttribute(!switcher.on, url: NSFileManager.docDirURL)
    }

}
