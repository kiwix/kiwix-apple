//
//  LibraryAutoRefreshTBVC.swift
//  Kiwix
//
//  Created by Chris Li on 8/15/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit

class LibraryAutoRefreshTBVC: UITableViewController {
    let sectionHeader = ["day", "week", "month"]
    let sectionHeaderLocalized = [LocalizedStrings.day, LocalizedStrings.week, LocalizedStrings.month]
    let enableAutoRefreshSwitch = UISwitch()
    var checkedRowIndexPath: NSIndexPath?
    var libraryAutoRefreshDisabled = Preference.libraryAutoRefreshDisabled
    var libraryRefreshInterval = Preference.libraryRefreshInterval
    let timeIntervals: [String: [Double]] = {
        let hour = 3600.0
        let day = 24.0 * hour
        let week = 7.0 * day
        
        let timeIntervals = ["day": [day, 3*day, 5*day], "week": [week, 2*week, 4*week]]
        return timeIntervals
    }()
    
    let dateComponentsFormatter: NSDateComponentsFormatter = {
        let formatter = NSDateComponentsFormatter()
        formatter.unitsStyle = NSDateComponentsFormatterUnitsStyle.Full
        formatter.maximumUnitCount = 1
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = LocalizedStrings.libraryAutoRefresh
        enableAutoRefreshSwitch.addTarget(self, action: "switcherValueChanged:", forControlEvents: .ValueChanged)
        enableAutoRefreshSwitch.on = !libraryAutoRefreshDisabled
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        Preference.libraryAutoRefreshDisabled = libraryAutoRefreshDisabled
        Preference.libraryRefreshInterval = libraryRefreshInterval
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
            cell.textLabel?.text = LocalizedStrings.enableAutoRefresh
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
        if section == 0 {
            return LocalizedStrings.autoRefreshHelpMessage
        } else {
            return sectionHeaderLocalized[section-1]
        }
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
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if section == 0 {
            if let view = view as? UITableViewHeaderFooterView {
                view.textLabel?.text = LocalizedStrings.autoRefreshHelpMessage
            }
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

extension LocalizedStrings {
    class var day: String {return NSLocalizedString("day", comment: "Setting: Library Auto Refresh Page section title")}
    class var week: String {return NSLocalizedString("week", comment: "Setting: Library Auto Refresh Page section title")}
    class var month: String {return NSLocalizedString("month", comment: "Setting: Library Auto Refresh Page section title")}
    class var enableAutoRefresh: String {return NSLocalizedString("Enable Auto Refresh", comment: "Setting: Library Auto Refresh Page")}
    class var autoRefreshHelpMessage: String {return NSLocalizedString("When enabled, your library will refresh automatically according to the selected interval when you open the app.", comment: "Setting: Library Auto Refresh Page")}
}