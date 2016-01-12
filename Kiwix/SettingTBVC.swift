//
//  SettingTBVC.swift
//  Kiwix
//
//  Created by Chris on 12/12/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit

class SettingTBVC: UITableViewController {

    let sectionHeader = [LocalizedStrings.library, LocalizedStrings.reading, LocalizedStrings.misc]
    let cellTextlabels = [[LocalizedStrings.libraryAutoRefresh, LocalizedStrings.libraryUseCelluarData],
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
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
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
        guard Preference.haveRateKiwix == false else {return}
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
    class var libraryUseCelluarData: String {return NSLocalizedString("Refresh Using Celluar Data", comment: "Setting: Library Use Celluar Data")}
    class var fontSize: String {return NSLocalizedString("Font Size", comment: "Setting: Font Size")}
    class var adjustLayout: String {return NSLocalizedString("Adjust Layout", comment: "Setting: Adjust Layout")}
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
