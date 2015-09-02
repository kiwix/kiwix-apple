//
//  ScalePageToFitTBVC.swift
//  Kiwix
//
//  Created by Chris Li on 8/15/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit

class ScalePageToFitTBVC: UITableViewController {
    
    var webViewScalePageToFitWidth = Preference.webViewScalePageToFitWidth
    let webViewScalePageToFitWidthSwitch = UISwitch()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Auto Scale Page"
        webViewScalePageToFitWidthSwitch.addTarget(self, action: "switcherValueChanged:", forControlEvents: .ValueChanged)
        webViewScalePageToFitWidthSwitch.on = webViewScalePageToFitWidth
        
        tableView.tableFooterView = tableFooterView(tableView.frame.width)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        Preference.webViewScalePageToFitWidth = webViewScalePageToFitWidth
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

        cell.textLabel?.text = "Enable Auto Scale"
        cell.accessoryView = webViewScalePageToFitWidthSwitch

        return cell
    }
    
    func tableFooterView(width: CGFloat) -> UIView {
        let preferredWidth = UIDevice.currentDevice().userInterfaceIdiom == .Pad ? self.navigationController!.preferredContentSize.width : width
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            return Utilities.tableHeaderFooterView(withMessage: "On iPad, we recommend you to leave this option off.", preferredWidth: preferredWidth, textAlientment: .Center)
        } else {
            let message = "For articles that are not mobile friendly, turning this on will show their original layout, i.e., the desktop version. \n\nIn this case, turning this option on and rotate your iPhone in landscape will often result in better reading experience. (Don't forget to turn off rotation lock on your device.) \n\nFor articles that are mobile friendly, this option will not affect how the article appears on screen."
            return Utilities.tableHeaderFooterView(withMessage: message, preferredWidth: preferredWidth, textAlientment: .Left)
        }
    }
    
    func switcherValueChanged(switcher: UISwitch) {
        webViewScalePageToFitWidth = switcher.on
    }
}
