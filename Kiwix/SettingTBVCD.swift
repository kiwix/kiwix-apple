//
//  SettingTBVCD.swift
//  Kiwix
//
//  Created by Chris on 1/3/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

extension SettingTBVC {
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
                if Preference.libraryAutoRefreshDisabled {
                    return LocalizedStrings.disabled
                } else {
                    return dateComponentsFormatter.stringFromTimeInterval(Preference.libraryRefreshInterval)
                }
            case NSIndexPath(forRow: 1, inSection: 0):
                return Preference.libraryRefreshAllowCellularData ? LocalizedStrings.on : LocalizedStrings.off
            case NSIndexPath(forRow: 0, inSection: 1):
                return Utilities.formattedPercentString(NSNumber(double: Preference.webViewZoomScale / 100))
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
        if section == tableView.numberOfSections - 1 {
            return String(format: LocalizedStrings.versionString, NSBundle.shortVersionString)
        } else {
            return nil
        }
    }
    
    override func tableView(tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        if section == tableView.numberOfSections - 1 {
            if let view = view as? UITableViewHeaderFooterView {
                view.textLabel?.textAlignment = .Center
            }
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
        case LocalizedStrings.fontSize:
            performSegueWithIdentifier("ReadingFontSize", sender: self)
        case LocalizedStrings.adjustLayout:
            performSegueWithIdentifier("AdjustLayout", sender: self)
        case LocalizedStrings.rateKiwix:
            showRateKiwixAlert(showRemindLater: false)
        case LocalizedStrings.about:
            performSegueWithIdentifier("MiscAbout", sender: self)
            
            //            case LocalizedStrings.homePage:[  ]
            //            self.performSegueWithIdentifier("HomePage", sender: self)
            //            case LocalizedStrings.readingOptimization:
            //                self.performSegueWithIdentifier("ReadingOptimization", sender: self)
            //            case LocalizedStrings.booksToInclude:
            //                self.performSegueWithIdentifier("SearchRange", sender: self)
            //            case LocalizedStrings.rateKiwix:
            //                self.goRateInAppStore()
            //            case LocalizedStrings.emailFeedback:
            //                self.sendEmailFeedback()
            //            case LocalizedStrings.about:
            //                self.performSegueWithIdentifier("About", sender: self)
            //            case "Toggle feedback alert":
            //                self.showRateUsPrompt()
            //            case "File Browser":
            //                self.showFileManager()
        default:
            break
        }
    }
}