//
//  SettingDetailController.swift
//  Kiwix
//
//  Created by Chris Li on 7/13/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import ProcedureKit

class SettingDetailController: UITableViewController {
    
    let switchControl = UISwitch()
    var page = SettingDetailControllerContentType.BackupLocalFiles

    override func viewDidLoad() {
        super.viewDidLoad()
        switch page {
        case .BackupLocalFiles:
            title = LocalizedStrings.backupLocalFiles
            switchControl.isOn = !(FileManager.getSkipBackupAttribute(item: FileManager.docDirURL) ?? false)
        case .SearchHistory:
            title = LocalizedStrings.searchHistory
        }
        
        switchControl.addTarget(self, action: #selector(SettingDetailController.switchValueChanged), for: .valueChanged)
    }
    
    func switchValueChanged() {
        if page == .BackupLocalFiles {
            FileManager.setSkipBackupAttribute(!switchControl.isOn, url: FileManager.docDirURL)
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch page {
        case .BackupLocalFiles:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            cell.textLabel?.text = LocalizedStrings.backupLocalFiles
            cell.accessoryView = switchControl
            return cell
        case .SearchHistory:
            let cell = tableView.dequeueReusableCell(withIdentifier: "CenterTextCell", for: indexPath)
            cell.textLabel?.text = NSLocalizedString("Clear Search History", comment: "")
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch page {
        case .SearchHistory:
            Preference.RecentSearch.terms = [String]()
            let controller = UIAlertController(title: NSLocalizedString("Cleared", comment: "Setting, search history cleared"),
                                               message: NSLocalizedString("Your search history has been cleared!", comment: "Setting, search history cleared"),
                                               preferredStyle: .alert)
            let done = UIAlertAction(title: LocalizedStrings.done, style: .default, handler: nil)
            controller.addAction(done)
            present(controller, animated: true, completion: nil)
        default:
            return
        }
    }
}

enum SettingDetailControllerContentType: String {
    case BackupLocalFiles, SearchHistory
}
