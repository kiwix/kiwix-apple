//
//  LibraryAutoRefreshTBVC.swift
//  Kiwix
//
//  Created by Chris Li on 8/15/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit

class LibraryAutoRefreshTBVC: UITableViewController {
    let sectionHeader = ["hour", "day", "week", "month"]
    let enableAutoRefreshSwitch = UISwitch()
    var checkedRowIndexPath: NSIndexPath?
    var libraryAutoRefreshDisabled = Preference.libraryAutoRefreshDisabled
    var libraryRefreshInterval = Preference.libraryRefreshInterval
    let timeIntervals: [String: [Double]] = {
        let hour = 3600.0
        let day = 24.0 * hour
        let week = 7.0 * day
        
        let timeIntervals = ["hour": [hour, 3*hour, 6*hour, 12*hour], "day": [day, 3*day], "week": [week, 2*week, 4*week]]
        return timeIntervals
    }()
    
    let dateComponentsFormatter: NSDateComponentsFormatter = {
        let formatter = NSDateComponentsFormatter()
        formatter.unitsStyle = NSDateComponentsFormatterUnitsStyle.Full
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        enableAutoRefreshSwitch.addTarget(self, action: "switcherValueChanged:", forControlEvents: .ValueChanged)
        enableAutoRefreshSwitch.on = !libraryAutoRefreshDisabled
        self.title = "Library Auto Refresh"
        tableView.tableHeaderView = tableHeaderView(tableView.frame.width)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        Preference.libraryAutoRefreshDisabled = libraryAutoRefreshDisabled
        Preference.libraryRefreshInterval = libraryRefreshInterval
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        tableView.tableHeaderView = tableHeaderView(size.width)
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if libraryAutoRefreshDisabled {
            return 1
        } else {
            return timeIntervals.keys.count + 1
        }
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            let sectionHeader = self.sectionHeader[section-1]
            return timeIntervals[sectionHeader]!.count
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        if indexPath.section == 0 {
            cell.textLabel?.text = "Enable Auto Refresh"
            cell.accessoryView = enableAutoRefreshSwitch
        } else {
            let sectionHeader = self.sectionHeader[indexPath.section-1]
            let interval = timeIntervals[sectionHeader]![indexPath.row]
            cell.textLabel?.text = dateComponentsFormatter.stringFromTimeInterval(interval)
            if interval == libraryRefreshInterval {
                cell.accessoryType = .Checkmark
                checkedRowIndexPath = indexPath
            } else {
                cell.accessoryType = .None
            }
            cell.accessoryView = nil
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section != 0 {
            return sectionHeader[section-1]
        } else {
            return nil
        }
    }
    
    func tableHeaderView(width: CGFloat) -> UIView {
        let headerMessage = "When turned on, your library will refresh automatically according to the selected interval when you open the app or enter library."
        let preferredWidth = UIDevice.currentDevice().userInterfaceIdiom == .Pad ? self.navigationController!.preferredContentSize.width : width
        return Utilities.tableHeaderFooterView(withMessage: headerMessage, preferredWidth: preferredWidth, textAlientment: .Left)
    }
    
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section >= 1 {
            if let checkedRowIndexPath = checkedRowIndexPath, let cell = tableView.cellForRowAtIndexPath(checkedRowIndexPath) {
                cell.accessoryType = .None
            }
            
            if let cell = tableView.cellForRowAtIndexPath(indexPath) {
                cell.accessoryType = .Checkmark
            }
            
            checkedRowIndexPath = indexPath
            let sectionHeader = self.sectionHeader[indexPath.section-1]
            libraryRefreshInterval = timeIntervals[sectionHeader]![indexPath.row]
        }
    }
    
    // MARK: - Action
    
    func switcherValueChanged(switcher: UISwitch) {
        libraryAutoRefreshDisabled = !switcher.on
        if libraryAutoRefreshDisabled {
            tableView.deleteSections(NSIndexSet(indexesInRange: NSMakeRange(1, sectionHeader.count-1)), withRowAnimation: UITableViewRowAnimation.Fade)
        } else {
            tableView.insertSections(NSIndexSet(indexesInRange: NSMakeRange(1, sectionHeader.count-1)), withRowAnimation: .Fade)
        }
    }
}
