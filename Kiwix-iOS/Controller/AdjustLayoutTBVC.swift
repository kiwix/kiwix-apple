//
//  AdjustLayoutTBVC.swift
//  Kiwix
//
//  Created by Chris on 1/10/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class AdjustLayoutTBVC: UITableViewController {

    var adjustPageLayout = Preference.webViewInjectJavascriptToAdjustPageLayout
    let adjustPageLayoutSwitch = UISwitch()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = LocalizedStrings.adjustLayout
        adjustPageLayoutSwitch.addTarget(self, action: #selector(AdjustLayoutTBVC.switcherValueChanged(_:)), forControlEvents: .ValueChanged)
        adjustPageLayoutSwitch.on = adjustPageLayout
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        Preference.webViewInjectJavascriptToAdjustPageLayout = adjustPageLayout
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
        cell.textLabel?.text = LocalizedStrings.adjustLayout
        cell.accessoryView = adjustPageLayoutSwitch
        return cell
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return LocalizedStrings.adjustPageLayoutMessage
    }
    
    // MARK: - Actions
    
    func switcherValueChanged(switcher: UISwitch) {
        if switcher == adjustPageLayoutSwitch {
            adjustPageLayout = switcher.on
        }
    }

}

extension LocalizedStrings {
    class var adjustPageLayout: String {return NSLocalizedString("Adjust Page Layout (Beta)", comment: "Setting: Reading Optimization")}
    class var adjustPageLayoutMessage: String {return NSLocalizedString("When turned on, Kiwix will try its best to adjust the page layout for your device.", comment: "Setting: Reading Optimization")}
}
