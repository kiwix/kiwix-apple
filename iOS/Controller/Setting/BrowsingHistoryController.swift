//
//  BrowseHistoryController.swift
//  Kiwix
//
//  Created by Chris Li on 3/7/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class BrowseHistoryController: UITableViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        if indexPath.section == 0 {
            cell.textLabel?.text = Localized.Setting.History.clearSearchHistory
        } else {
            cell.textLabel?.text = Localized.Setting.History.clearSearchHistory
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
    }

}
