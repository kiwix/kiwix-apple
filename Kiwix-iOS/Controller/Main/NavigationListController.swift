//
//  NavigationListController.swift
//  Kiwix
//
//  Created by Chris Li on 11/21/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit

class NavigationListController: UITableViewController {
    
    var type: NavigationListType?
    var urls = [URL]() {
        didSet {
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(dismiss(sender:)))
    }
    
    func dismiss(sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return urls.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let url = urls[indexPath.row]
        cell.textLabel?.text = url.lastPathComponent

        return cell
    }
}
