//
//  DownloaderAllowCellularData.swift
//  Kiwix
//
//  Created by Chris Li on 8/24/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit

class DownloaderAllowCellularData: UITableViewController {

    var downloaderAllowCellularData = Preference.downloaderAllowCellularData
    let downloaderAllowCellularDataSwitch = UISwitch()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Cellular Data"
        downloaderAllowCellularDataSwitch.addTarget(self, action: "switcherValueChanged:", forControlEvents: .ValueChanged)
        downloaderAllowCellularDataSwitch.on = downloaderAllowCellularData
        
        tableView.tableFooterView = tableFooterView(tableView.frame.width)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        Preference.downloaderAllowCellularData = downloaderAllowCellularData
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        tableView.tableFooterView = tableFooterView(size.width)
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
        
        cell.textLabel?.text = "Allow Cellular Data"
        cell.accessoryView = downloaderAllowCellularDataSwitch
        
        return cell
    }
    
    func tableFooterView(width: CGFloat) -> UIView {
        let preferredWidth = UIDevice.currentDevice().userInterfaceIdiom == .Pad ? self.navigationController!.preferredContentSize.width : width
        let message = "When turned off, you can still start book download. The download will start automatically when you have Wifi access.\n\nThis option doesn't apply to ongoing or paused download task."
        return Utilities.tableHeaderFooterView(withMessage: message, preferredWidth: preferredWidth, textAlientment: .Left)
    }
    
    func switcherValueChanged(switcher: UISwitch) {
        downloaderAllowCellularData = switcher.on
    }

}
