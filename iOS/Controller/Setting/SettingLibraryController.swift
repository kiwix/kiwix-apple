//
//  SettingLibraryController.swift
//  iOS
//
//  Created by Chris Li on 7/16/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit

class SettingLibraryController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }

    func configureRefreshTokenTitle() {
//        guard let lastRefreshTime = Defaults[.libraryLastRefreshTime] else {return}
        
//        let components = Calendar.current.dateComponents([.year, .month, .weekOfMonth, .day, .hour, .minute, .second], from: lastRefreshTime, to: Date())
//        let formatter = DateComponentsFormatter()
//        formatter.unitsStyle = .full
//        if let year = components.year, year > 0 {
//            formatter.allowedUnits = .year
//        } else if let month = components.month, month > 0 {
//            formatter.allowedUnits = .month
//        } else if let week = components.weekOfMonth, week > 0 {
//            formatter.allowedUnits = .weekOfMonth
//        } else if let day = components.day, day > 0 {
//            formatter.allowedUnits = .day
//        } else if let hour = components.hour, hour > 0 {
//            formatter.allowedUnits = [.hour]
//        } else if let minute = components.minute, minute > 0 {
//            formatter.allowedUnits = .minute
//        } else {
//            formatter.allowedUnits = .second
//        }
//
//        guard let formatted = formatter.string(from: components) else {return}
//        refreshControl.attributedTitle = NSAttributedString(string: NSLocalizedString(
//            String(format: "Last refresh: %@ ago", formatted), comment: "Time elapsed since last library refresh"))
    }

}
