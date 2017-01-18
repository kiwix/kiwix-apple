//
//  SettingController.swift
//  Kiwix
//
//  Created by Chris Li on 1/18/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class SettingController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    @IBAction func dismissButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)


        return cell
    }

}
