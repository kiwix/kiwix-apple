//
//  SettingTBVC.swift
//  Kiwix
//
//  Created by Chris on 12/12/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit

class SettingTBVC: UITableViewController {
    private(set) var sectionHeader: [String?] = [nil, LocalizedStrings.misc]
    private(set) var cellTitles = [[LocalizedStrings.backupLocalFiles, LocalizedStrings.fontSize, LocalizedStrings.searchHistory],
                          [LocalizedStrings.rateKiwix, LocalizedStrings.about]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = LocalizedStrings.settings
        clearsSelectionOnViewWillAppear = true
        showRateKiwixIfNeeded()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return cellTitles.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellTitles[section].count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        
        let title = cellTitles[indexPath.section][indexPath.row]
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = {
            switch title {
            case LocalizedStrings.backupLocalFiles:
                guard let skipBackup = NSFileManager.getSkipBackupAttribute(item: NSFileManager.docDirURL) else {return ""}
                return skipBackup ? LocalizedStrings.off: LocalizedStrings.on
            case LocalizedStrings.fontSize:
                return String.formattedPercentString(Preference.webViewZoomScale / 100)
            default:
                return nil
            }
        }()
        
        return cell
    }
    
    // MARK: - Table View Delegate
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionHeader[section]
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard section == tableView.numberOfSections - 1 else {return nil}
        var footnote = String(format: LocalizedStrings.settingFootnote, NSBundle.appShortVersion)
        switch UIApplication.buildStatus {
        case .Alpha, .Beta:
            footnote += (UIApplication.buildStatus == .Alpha ? " Alpha" : " Beta")
            footnote += "\n"
            footnote += "Build " + NSBundle.buildVersion
            return footnote
        case .Release:
            return footnote
        }
    }
    
    override func tableView(tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        guard section == tableView.numberOfSections - 1 else {return}
        if let view = view as? UITableViewHeaderFooterView {
            view.textLabel?.textAlignment = .Center
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        defer {tableView.deselectRowAtIndexPath(indexPath, animated: true)}
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        guard let text = cell?.textLabel?.text else {return}
        switch text {
        case LocalizedStrings.backupLocalFiles:
            let controller = UIStoryboard(name: "Setting", bundle: nil)
                .instantiateViewControllerWithIdentifier("SettingDetailController") as! SettingDetailController
            controller.page = .BackupLocalFiles
            navigationController?.pushViewController(controller, animated: true)
        case LocalizedStrings.searchHistory:
            let controller = UIStoryboard(name: "Setting", bundle: nil)
                .instantiateViewControllerWithIdentifier("SettingDetailController") as! SettingDetailController
            controller.page = .SearchHistory
            navigationController?.pushViewController(controller, animated: true)
        case LocalizedStrings.fontSize:
            let controller = UIStoryboard(name: "Setting", bundle: nil)
                .instantiateViewControllerWithIdentifier("FontSizeController") as! FontSizeController
            navigationController?.pushViewController(controller, animated: true)
        case LocalizedStrings.rateKiwix:
            showRateKiwixAlert(showRemindLater: false)
        case LocalizedStrings.about:
            let controller = UIStoryboard(name: "Setting", bundle: nil)
                .instantiateViewControllerWithIdentifier("WebViewController") as! WebViewController
            controller.page = .About
            navigationController?.pushViewController(controller, animated: true)
        default:
            break
        }
    }
    
    // MARK: - Rate Kiwix
    
    func showRateKiwixIfNeeded() {
        guard Preference.haveRateKiwix == false else {return}
        guard let firstActiveDate = Preference.activeUseHistory.first else {return}
        let installtionIsOldEnough = NSDate().timeIntervalSinceDate(firstActiveDate) > 3600.0 * 24 * 7
        let hasActivelyUsed = Preference.activeUseHistory.count > 10
        if installtionIsOldEnough && hasActivelyUsed {
            showRateKiwixAlert(showRemindLater: true)
        }
    }
    
    func showRateKiwixAlert(showRemindLater showRemindLater: Bool) {
        let alert = UIAlertController(title: LocalizedStrings.rateKiwixTitle, message: LocalizedStrings.rateKiwixMessage, preferredStyle: .Alert)
        let remindLater = UIAlertAction(title: LocalizedStrings.rateLater, style: .Default) { (action) -> Void in
            Preference.activeUseHistory.removeAll()
        }
        let remindNever = UIAlertAction(title: LocalizedStrings.rateNever, style: .Default) { (action) -> Void in
            Preference.haveRateKiwix = true
        }
        let rateNow = UIAlertAction(title: LocalizedStrings.rateNow, style: .Cancel) { (action) -> Void in
            self.goRateInAppStore()
            Preference.haveRateKiwix = true
        }
        let cancel = UIAlertAction(title: LocalizedStrings.cancel, style: .Default, handler: nil)
        
        if showRemindLater {
            alert.addAction(remindLater)
            alert.addAction(remindNever)
            alert.addAction(rateNow)
        } else {
            alert.addAction(rateNow)
            alert.addAction(cancel)
        }
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func goRateInAppStore() {
        let url = NSURL(string: "http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=997079563&pageNumber=0&sortOrdering=2&type=Purple+Software&mt=8")!
        UIApplication.sharedApplication().openURL(url)
    }
    
    // MARK: - Actions
    
    @IBAction func dismissButtonTapped(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

}

extension LocalizedStrings {
    static let settings = NSLocalizedString("Settings", comment: "Settings")
    
    static let backupLocalFiles = NSLocalizedString("Backup Local Files", comment: "Setting")
    static let fontSize = NSLocalizedString("Font Size", comment: "Setting")
    static let searchHistory = NSLocalizedString("Search History", comment: "Setting")
    
    static let misc = NSLocalizedString("Misc", comment: "Setting")
    static let rateKiwix = NSLocalizedString("Give Kiwix a rate!", comment: "Setting")
    static let about = NSLocalizedString("About", comment: "Setting")
    static let settingFootnote = NSLocalizedString("Kiwix for iOS v%@", comment: "Version footnote (please translate 'v' as version)")
    
    //MARK: -  Rate Kiwix
    class var rateKiwixTitle: String {return NSLocalizedString("Give Kiwix a rate!", comment: "Rate Kiwix in App Store Alert Title")}
    class var rateNow: String {return NSLocalizedString("Rate Now", comment: "Rate Kiwix in App Store Alert Action")}
    class var rateLater: String {return NSLocalizedString("Remind me later", comment: "Rate Kiwix in App Store Alert Action")}
    class var rateNever: String {return NSLocalizedString("Never remind me again", comment: "Rate Kiwix in App Store Alert Action")}
    class var rateKiwixMessage: String {return NSLocalizedString("We hope you enjoyed using Kiwix so far. Would you like to give us a rate in App Store?", comment: "Rate Kiwix in App Store Alert Message")}
}
