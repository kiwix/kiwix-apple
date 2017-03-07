//
//  NotificationSettingController.swift
//  Kiwix
//
//  Created by Chris Li on 1/20/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class NotificationSettingController: UITableViewController {

    let rows = [[Localized.Setting.Notifications.libraryRefresh],
                [Localized.Setting.Notifications.bookDownloadFinish]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = Localized.Setting.notifications
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return rows.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let switchView = UISwitch()
        switchView.tag = indexPath.section
        switchView.addTarget(self, action: #selector(switchValueChanged(switchView:)), for: .valueChanged)
        switch switchView.tag {
        case 0:
            switchView.isOn = Preference.Notifications.libraryRefresh
//        case 1:
//            switchView.isOn = Preference.Notifications.bookUpdateAvailable
        case 1:
            switchView.isOn = Preference.Notifications.bookDownloadFinish
        default:
            break
        }
        
        cell.textLabel?.text = rows[indexPath.section][indexPath.row]
        cell.accessoryView = switchView
        
        return cell
    }
    
    func switchValueChanged(switchView: UISwitch) {
        switch switchView.tag {
        case 0:
            Preference.Notifications.libraryRefresh = !Preference.Notifications.libraryRefresh
//        case 1:
//            Preference.Notifications.bookUpdateAvailable = !Preference.Notifications.bookUpdateAvailable
        case 1:
            Preference.Notifications.bookDownloadFinish = !Preference.Notifications.bookDownloadFinish
        default:
            break
        }
    }

}
