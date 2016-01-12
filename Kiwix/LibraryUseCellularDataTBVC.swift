//
//  LibraryUseCellularDataTBVC.swift
//  Kiwix
//
//  Created by Chris Li on 8/24/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit

class LibraryUseCellularDataTBVC: UITableViewController {

    var libraryRefreshAllowCellularData = Preference.libraryRefreshAllowCellularData
    let libraryrefreshAllowCellularDataSwitch = UISwitch()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = LocalizedStrings.libraryUseCelluarData
        libraryrefreshAllowCellularDataSwitch.addTarget(self, action: "switcherValueChanged:", forControlEvents: .ValueChanged)
        libraryrefreshAllowCellularDataSwitch.on = libraryRefreshAllowCellularData
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        Preference.libraryRefreshAllowCellularData = libraryRefreshAllowCellularData
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
        
        cell.textLabel?.text = LocalizedStrings.libraryUseCelluarData
        cell.accessoryView = libraryrefreshAllowCellularDataSwitch
        
        return cell
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Refresh Library"
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return LocalizedStrings.cellularLibraryRefreshMessage1 + "\n\n" + LocalizedStrings.cellularLibraryRefreshMessage2
    }
    
    // MARK: - Actions
    
    func switcherValueChanged(switcher: UISwitch) {
        if switcher == libraryrefreshAllowCellularDataSwitch {
            libraryRefreshAllowCellularData = switcher.on
        }
    }

}

extension LocalizedStrings {
    class var refreshLibraryUsingCellularData: String {return NSLocalizedString("Refresh Library Using Cellular Data", comment: "Setting: Use Celluar Data")}
    class var cellularLibraryRefreshMessage1: String {return NSLocalizedString("When enabled, library refresh will use cellular data.", comment: "Setting: Use Celluar Data")}
    class var cellularLibraryRefreshMessage2: String {return NSLocalizedString("Note: a 5-6MB database is downloaded every time the library refreshes.", comment: "Setting: Use Celluar Data")}
}
