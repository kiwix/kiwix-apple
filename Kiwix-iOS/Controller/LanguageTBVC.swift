//
//  LanguageTBVC.swift
//  Kiwix
//
//  Created by Chris on 12/12/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit
import CoreData

class LanguageTBVC: UITableViewController, NSFetchedResultsControllerDelegate {
    
    let managedObjectContext = UIApplication.appDelegate.managedObjectContext
    var showLanguageSet = Set<Language>()
    var showLanguages = [Language]()
    var hideLanguages = [Language]()
    var messageBarButtonItem = MessageBarButtonItem()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Languages"
        
        showLanguages = Language.fetch(displayed: true, context: managedObjectContext)
        hideLanguages = Language.fetch(displayed: false, context: managedObjectContext)
        showLanguages = sortByCountDesc(showLanguages)
        hideLanguages = sortByCountDesc(hideLanguages)
        showLanguageSet = Set(showLanguages)
        
        configureToolBar()
    }
    
    override func viewWillDisappear(animated: Bool) {
        let hasChange = showLanguageSet != Set(showLanguages)
        guard hasChange else {return}
        guard let libraryOnlineTBVC = self.navigationController?.topViewController as? LibraryOnlineTBVC else {return}
        libraryOnlineTBVC.refreshFetchedResultController()
    }
    
    func configureToolBar() {
        let spaceBarButtonItem = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace)
        setToolbarItems([spaceBarButtonItem, messageBarButtonItem, spaceBarButtonItem], animated: false)
        messageBarButtonItem.text = messageLabelText
    }
    
    var messageLabelText: String? {
        switch showLanguages.count {
        case 0:
            return LocalizedStrings.noLangSelected
        case 1:
            guard let name = showLanguages.first?.name else {return nil}
            return String(format: LocalizedStrings.oneLangSelected, name)
        case 2:
            guard let name1 = showLanguages[0].name else {return nil}
            guard let name2 = showLanguages[1].name else {return nil}
            return String(format: LocalizedStrings.twoLangSelected, name1, name2)
        default:
            return String(format: LocalizedStrings.someLangSelected, showLanguages.count)
        }
    }
    
    func sortByCountDesc(languages: [Language]) -> [Language] {
        return languages.sort { (language1, language2) -> Bool in
            guard let count1 = language1.books?.count else {return false}
            guard let count2 = language2.books?.count else {return false}
            if count1 == count2 {
                guard let name1 = language1.name else {return false}
                guard let name2 = language2.name else {return false}
                return name1.compare(name2) == .OrderedAscending
            } else {
                return count1 > count2
            }
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? showLanguages.count : hideLanguages.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        if indexPath.section == 0 {
            cell.textLabel?.text = showLanguages[indexPath.row].name
            cell.detailTextLabel?.text = showLanguages[indexPath.row].books?.count.description
        } else {
            cell.textLabel?.text = hideLanguages[indexPath.row].name
            cell.detailTextLabel?.text = hideLanguages[indexPath.row].books?.count.description
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if showLanguages.count == 0 {
            return section == 0 ? "" : "ALL       "
        } else {
            return section == 0 ? "SHOWING" : "HIDING"
        }
    }
    
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        func animateUpdates(originalIndexPath: NSIndexPath, destinationIndexPath: NSIndexPath) {
            tableView.beginUpdates()
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Right)
            tableView.insertRowsAtIndexPaths([destinationIndexPath], withRowAnimation: .Right)
            tableView.headerViewForSection(0)?.textLabel?.text = self.tableView(tableView, titleForHeaderInSection: 0)
            tableView.headerViewForSection(1)?.textLabel?.text = self.tableView(tableView, titleForHeaderInSection: 1)
            tableView.endUpdates()
        }
        
        if indexPath.section == 0 {
            let language = showLanguages[indexPath.row]
            language.isDisplayed = false
            hideLanguages.append(language)
            showLanguages.removeAtIndex(indexPath.row)
            hideLanguages = sortByCountDesc(hideLanguages)
            
            guard let row = hideLanguages.indexOf(language) else {tableView.reloadData(); return}
            let destinationIndexPath = NSIndexPath(forRow: row, inSection: 1)
            animateUpdates(indexPath, destinationIndexPath: destinationIndexPath)
        } else {
            let language = hideLanguages[indexPath.row]
            language.isDisplayed = true
            showLanguages.append(language)
            hideLanguages.removeAtIndex(indexPath.row)
            showLanguages = sortByCountDesc(showLanguages)
            
            guard let row = showLanguages.indexOf(language) else {tableView.reloadData(); return}
            let destinationIndexPath = NSIndexPath(forRow: row, inSection: 0)
            animateUpdates(indexPath, destinationIndexPath: destinationIndexPath)
        }
        
        messageBarButtonItem.text = messageLabelText
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if showLanguages.count == 0 && section == 0 {return CGFloat.min}
        return tableView.sectionHeaderHeight
    }

}

extension LocalizedStrings {
    class var noLangSelected: String {return NSLocalizedString("All languages will be shown", comment: "")}
    class var oneLangSelected: String {return NSLocalizedString("%@ is selected", comment: "")}
    class var twoLangSelected: String {return NSLocalizedString("%@ and %@ are selected", comment: "")}
    class var someLangSelected: String {return NSLocalizedString("%d languages are selected", comment: "")}
}