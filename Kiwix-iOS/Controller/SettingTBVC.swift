//
//  SettingTBVC.swift
//  Kiwix
//
//  Created by Chris on 12/12/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit

class SettingTBVC: UITableViewController {
    private(set) var sectionHeader = [LocalizedStrings.library, LocalizedStrings.reading,LocalizedStrings.misc]
    private(set) var cellTextlabels = [[LocalizedStrings.libraryAutoRefresh, LocalizedStrings.libraryUseCellularData, LocalizedStrings.libraryBackup],
                          [LocalizedStrings.fontSize, LocalizedStrings.adjustLayout],
                          [LocalizedStrings.rateKiwix, LocalizedStrings.about]]
    
    let dateComponentsFormatter: NSDateComponentsFormatter = {
        let formatter = NSDateComponentsFormatter()
        formatter.unitsStyle = NSDateComponentsFormatterUnitsStyle.Full
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = LocalizedStrings.settings
        clearsSelectionOnViewWillAppear = true
        showRateKiwixIfNeeded()
        
        if UIApplication.buildStatus == .Alpha {
            sectionHeader.append("Search")
            cellTextlabels.append(["Boost Factor 🚀"])
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sectionHeader.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellTextlabels[section].count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        
        cell.textLabel?.text = cellTextlabels[indexPath.section][indexPath.row]
        cell.detailTextLabel?.text = {
            switch indexPath {
            case NSIndexPath(forRow: 0, inSection: 0):
                return Preference.libraryAutoRefreshDisabled ? LocalizedStrings.disabled :
                    dateComponentsFormatter.stringFromTimeInterval(Preference.libraryRefreshInterval)
            case NSIndexPath(forRow: 1, inSection: 0):
                return Preference.libraryRefreshAllowCellularData ? LocalizedStrings.on : LocalizedStrings.off
            case NSIndexPath(forRow: 2, inSection: 0):
                guard let skipBackup = FileManager.getSkipBackupAttribute(item: FileManager.docDirURL) else {return ""}
                return skipBackup ? LocalizedStrings.off: LocalizedStrings.on
            case NSIndexPath(forRow: 0, inSection: 1):
                return String.formattedPercentString(Preference.webViewZoomScale / 100)
            case NSIndexPath(forRow: 1, inSection: 1):
                return Preference.webViewInjectJavascriptToAdjustPageLayout ? LocalizedStrings.on : LocalizedStrings.off
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
        var footnote = String(format: LocalizedStrings.versionString, NSBundle.appShortVersion)
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
        case LocalizedStrings.libraryAutoRefresh:
            performSegueWithIdentifier("LibraryAutoRefresh", sender: self)
        case LocalizedStrings.libraryUseCellularData:
            performSegueWithIdentifier("LibraryUseCellularData", sender: self)
        case LocalizedStrings.libraryBackup:
            performSegueWithIdentifier("LibraryBackup", sender: self)
        case LocalizedStrings.fontSize:
            performSegueWithIdentifier("ReadingFontSize", sender: self)
        case LocalizedStrings.adjustLayout:
            performSegueWithIdentifier("AdjustLayout", sender: self)
        case LocalizedStrings.rateKiwix:
            showRateKiwixAlert(showRemindLater: false)
        case LocalizedStrings.about:
            performSegueWithIdentifier("MiscAbout", sender: self)
        case "Boost Factor 🚀":
            performSegueWithIdentifier("SearchTune", sender: self)
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
    class var settings: String {return NSLocalizedString("Settings", comment: "Setting: Title")}
    class var versionString: String {return NSLocalizedString("Kiwix for iOS v%@", comment: "Version footnote (please translate 'v' as version)")}
    
    //MARK: -  Table Header Text
    class var library: String {return NSLocalizedString("Library ", comment: "Setting: Section Header")}
    class var reading: String {return NSLocalizedString("Reading", comment: "Setting: Section Header")}
    class var search: String {return NSLocalizedString("Search", comment: "Setting: Section Header")}
    class var misc: String {return NSLocalizedString("Misc", comment: "Setting: Section Header")}
    
    //MARK: -  Table Cell Text
    class var libraryAutoRefresh: String {return NSLocalizedString("Auto Refresh", comment: "Setting: Library Auto Refresh")}
    class var libraryUseCellularData: String {return NSLocalizedString("Refresh Using Cellular Data", comment: "Setting: Library Use Cellular Data")}
    class var libraryBackup: String {return NSLocalizedString("Backup Local Files", comment: "Setting: Backup Local Files")}
    class var fontSize: String {return NSLocalizedString("Font Size", comment: "Setting: Font Size")}
    class var adjustLayout: String {return NSLocalizedString("Adjust Layout", comment: "Setting: Adjust Layout")}
    class var booksToInclude: String {return NSLocalizedString("Books To Include", comment: "Setting: Books To Include")}
    class var rateKiwix: String {return NSLocalizedString("Please Rate Kiwix", comment: "Setting: Others")}
    class var emailFeedback: String {return NSLocalizedString("Send Email Feedback", comment: "Setting: Others")}
    class var about: String {return NSLocalizedString("About", comment: "Setting: Others")}
    
    //MARK: -  Rate Kiwix
    class var rateKiwixTitle: String {return NSLocalizedString("Give Kiwix a rate!", comment: "Rate Kiwix in App Store Alert Title")}
    class var rateNow: String {return NSLocalizedString("Rate Now", comment: "Rate Kiwix in App Store Alert Action")}
    class var rateLater: String {return NSLocalizedString("Remind me later", comment: "Rate Kiwix in App Store Alert Action")}
    class var rateNever: String {return NSLocalizedString("Never remind me again", comment: "Rate Kiwix in App Store Alert Action")}
    class var rateKiwixMessage: String {return NSLocalizedString("We hope you enjoyed using Kiwix so far. Would you like to give us a rate in App Store?", comment: "Rate Kiwix in App Store Alert Message")}
}
