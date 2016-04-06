//
//  LibraryTBVCUIElements.swift
//  Kiwix
//
//  Created by Chris on 10/20/15.
//  Copyright © 2015 kiwix.org. All rights reserved.
//

import UIKit

extension LibraryTBVC {
    
    // MARK: - View Configuration
    
    func configureTableView() {
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.backgroundColor = UIColor.groupTableViewBackgroundColor()
        tableView.tableFooterView = UIView()
        tableView.sectionIndexBackgroundColor = UIColor.groupTableViewBackgroundColor()
    }
    
    // MARK: - UIAlerts
    
    func showPreferredLanguageAlertIfNeeded() {
        guard let _ = Preference.libraryLastRefreshTime else {return}
        guard !Preference.libraryHasShownPreferredLanguagePrompt else {return}
        let preferredLangCodes = NSLocale.preferredLangCodes
        guard let message = preferredLanguagePromptMessage(preferredLangCodes) else {return}
        let applyFilterAction = UIAlertAction(title: LocalizedStrings.yes, style: .Default, handler: { (action) -> Void in
            for langCode in preferredLangCodes {
                let language = Language.fetch(langCode, context: self.managedObjectContext)
                language?.isDisplayed = true
            }
            self.refreshOnlineFetchedResultController()
        })
        let cancelAction = UIAlertAction(title: LocalizedStrings.no, style: .Cancel, handler: nil)
        let alert = UIAlertController(title: LocalizedStrings.langAutoFilterAlertTitle, message: message, actions: [applyFilterAction, cancelAction])
        presentViewController(alert, animated: true, completion: { () -> Void in
            Preference.libraryHasShownPreferredLanguagePrompt = true
        })
    }
    
    func preferredLanguagePromptMessage(var langCodes: [String]) -> String? {
        guard let lastLangCode = langCodes.last else {return nil}
        guard let lastLanguage = NSLocale.currentLocale().displayNameForKey(NSLocaleLanguageCode, value:lastLangCode) else {return nil}
        langCodes.removeLast()
        let languageConcatenated: String = {
            if langCodes.count == 0 {
                return lastLanguage
            } else {
                var langNames = Set<String>()
                for langCode in langCodes {
                    guard let langName = NSLocale.currentLocale().displayNameForKey(NSLocaleLanguageCode, value:langCode) else {continue}
                    langNames.insert(langName)
                }
                return langNames.joinWithSeparator(", ") + " " + LocalizedStrings.and + " " + lastLanguage
            }
        }()
        
        return String(format: LocalizedStrings.langAutoFilterAlertMessage, languageConcatenated)
    }

    // MARK: - Toolbar
    
    func configureToolBar(animated animated: Bool) {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            configureToolBarForOnlineTab(animated: animated)
        case 1:
            configureToolBarForDownloadingTab(animated: animated)
        case 2:
            configureToolBarForLocalTab(animated: animated)
        default:
            break
        }
    }
    
    func configureToolBarForOnlineTab(animated animated: Bool) {
        cloudMessageItem.text = messageLabelTextForOnlineTab
        let toolBarItems = [refreshLibButton, spaceBarButtonItem, cloudMessageItem,spaceBarButtonItem, langFilterButton]
        setToolbarItems(toolBarItems, animated: animated)
    }
    
    func configureToolBarForDownloadingTab(animated animated: Bool) {
        downloadMessageItem.text = messageLabelTextForDownladingTab
        let toolBarItems = [spaceBarButtonItem, downloadMessageItem, spaceBarButtonItem]
        setToolbarItems(toolBarItems, animated: animated)
    }
    
    func configureToolBarForLocalTab(animated animated: Bool) {
        localMessageItem.text = messageLabelTextForLocalTab
        let toolBarItems = [spaceBarButtonItem, localMessageItem, spaceBarButtonItem]
        setToolbarItems(toolBarItems, animated: animated)
    }
    
    // MARK: ToolBar Button Actions 
    
    func refreshLibrary(sender: UIBarButtonItem) {
        UIApplication.appDelegate.libraryRefresher.refresh()
    }
    
    func showLangFilter(sender: UIBarButtonItem) {
        performSegueWithIdentifier("ShowLangFilter", sender: sender)
    }
//
//    func pauseAllDownloads(sender: UIBarButtonItem) {
//        Downloader.sharedInstance.pauseAllOnGoingDownloads()
//    }
//    
//    func resumeAllDownloads(sender: UIBarButtonItem) {
//        Downloader.sharedInstance.resumeAllDownloads()
//        configureToolBarForDownloadingTab(animated: true)
//    }
//    
//    func allowCellularDownload(sender: UIBarButtonItem) {
//        Preference.downloaderAllowCellularData = true
//        configureToolBarForDownloadingTab(animated: true)
//    }
//    
//    func disableCellularDownload(sender: UIBarButtonItem) {
//        Preference.downloaderAllowCellularData = false
//        configureToolBarForDownloadingTab(animated: true)
//    }
//    
//    func manualScanDocDir(sender: UIBarButtonItem) {
//        ZimMultiReader.sharedInstance.update()
//        let actionOK = UIAlertAction(title: LocalizedStrings.ok, style: .Cancel, handler: nil)
//        let alert = Utilities.alertWith(LocalizedStrings.manualScanCompleted, message: LocalizedStrings.manualScanCompletedMessage, actions: [actionOK])
//        self.navigationController?.presentViewController(alert, animated: true, completion: nil)
//    }
    
//    func editLocalLibrary(sender: UIBarButtonItem) {
//        tableView.setEditing(!tableView.editing, animated: true)
//    }
    
    // MARK: - Message Toolbar Label
    
    func refreshMessageLabelText() {
        switch segmentedControl.selectedSegmentIndex {
        case 0: cloudMessageItem.text = messageLabelTextForOnlineTab
        case 1: downloadMessageItem.text = messageLabelTextForDownladingTab
        case 2: localMessageItem.text = messageLabelTextForLocalTab
        default: break
        }
    }

    var messageLabelTextForOnlineTab: String? {
        if UIApplication.libraryRefresher.isRetrieving {return LocalizedStrings.retrieving}
        if UIApplication.libraryRefresher.isProcessing {return LocalizedStrings.processing}
        
        guard let libraryLastRefreshTime = Preference.libraryLastRefreshTime else {return LocalizedStrings.refreshNotYet}
        let interval = libraryLastRefreshTime.timeIntervalSinceNow * -1.0
        guard interval > 60.0 else {return LocalizedStrings.refreshedJustNow}
        
        let formatter = NSDateComponentsFormatter()
        formatter.allowedUnits = [.Year, .Month, .WeekOfMonth, .Day, .Hour, .Minute]
        formatter.unitsStyle = NSDateComponentsFormatterUnitsStyle.Short
        if let formattedInterval = formatter.stringFromTimeInterval(interval) {
            return String(format: LocalizedStrings.refreshedSomeTimeAgo, formattedInterval)
        } else {
            return LocalizedStrings.refreshTimeUnknown
        }
    }

    var messageLabelTextForDownladingTab: String {
        let taskCount = selectedFetchedResultController.fetchedObjects?.count ?? 0
        switch taskCount {
        case 0: return LocalizedStrings.downloadNoBook
        case 1: return LocalizedStrings.downloadOneBook
        default: return String(format: LocalizedStrings.downloadSomeBook, taskCount)
        }
    }
    
    var messageLabelTextForLocalTab: String {
        let readerCount = selectedFetchedResultController.fetchedObjects?.count ?? 0
        switch readerCount {
        case 0: return LocalizedStrings.localNoBook
        case 1: return LocalizedStrings.localOneBook
        default: return String(format: LocalizedStrings.localSomeBook, readerCount)
        }
    }
}

extension LocalizedStrings {
    // MARK: - Toolbar Label
    class var retrieving: String {return NSLocalizedString("Retrieving...", comment: "Library ToolBar: Refresh Status")}
    class var processing: String {return NSLocalizedString("Processing...", comment: "Library ToolBar: Refresh Status")}
    class var refreshedJustNow: String {return NSLocalizedString("Last Refresh: just now", comment: "Library ToolBar: Refresh Status")}
    class var refreshedSomeTimeAgo: String {return NSLocalizedString("Last Refresh: %@ ago", comment: "Library ToolBar: Refresh Status")}
    class var refreshTimeUnknown: String {return NSLocalizedString("Last Refresh: Unknown", comment: "Library ToolBar: Refresh Status")}
    class var refreshNotYet: String {return NSLocalizedString("Not yet refreshed", comment: "Library ToolBar: Refresh Status")}
    class var downloadNoBook: String {return NSLocalizedString("No book is downloading", comment: "Library ToolBar: Download Status")}
    class var downloadOneBook: String {return NSLocalizedString("1 book is downloading", comment: "Library ToolBar: Download Status")}
    class var downloadSomeBook: String {return NSLocalizedString("%d books are downloading", comment: "Library ToolBar: Download Status")}
    class var localNoBook: String {return NSLocalizedString("No local book", comment: "Library ToolBar: Local Status")}
    class var localOneBook: String {return NSLocalizedString("1 local book", comment: "Library ToolBar: Local Status")}
    class var localSomeBook: String {return NSLocalizedString("%d local books", comment: "Library ToolBar: Local Status")}
    
    // MARK: - Filter Alert
    class var langAutoFilterAlertTitle: String {return NSLocalizedString("Only Show Preferred Language?", comment: "Library: Language Filter Prompt")}
    class var langAutoFilterAlertMessage: String {return NSLocalizedString("We have found you may know %@, would you like to filter the library by these languages?", comment: "Library: Language Filter Prompt")}
    
    // MARK: - Manual Scan Alert
    class var manualScanCompleted: String {return NSLocalizedString("Manual Scan Completed", comment: "Library: Manual Scan Alert")}
    class var manualScanCompletedMessage: String {return NSLocalizedString("The list of local books is now updated.", comment: "Library: Manual Scan Alert")}
    
    // MARK: - Cell Accessory Button Alert
    class var spaceAlert: String {return NSLocalizedString("Space alert", comment: "Library: Download Space Alert")}
    class var spaceAlertMessage: String {return NSLocalizedString("This book will take up more than 80% of the free space on your device.", comment: "Library: Download Space Alert")}
    class var proceed: String {return NSLocalizedString("Proceed", comment: "Library: Download Space Alert")}
    class var notEnoughSpaceTitle: String {return NSLocalizedString("Not enough space", comment: "Library: Download Space Alert")}
    class var notEnoughSpaceMessage: String {return NSLocalizedString("Please free up some space and try again.", comment: "Library: Download Space Alert")}
    class var deleteAlertTitle: String {return NSLocalizedString("Delete the book?", comment: "Library: Download Space Alert")}
    class var deleteAlertMessage: String {return NSLocalizedString("This is not recoverable.", comment: "Library: Download Space Alert")}
}
