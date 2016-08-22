//
//  LanguageFilterController.swift
//  Kiwix
//
//  Created by Chris Li on 8/22/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import CoreData

class LanguageFilterController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var sortSegmentedControl: UISegmentedControl!
    @IBOutlet weak var langNameSegmentedControl: UISegmentedControl!
    
    let managedObjectContext = NSManagedObjectContext.mainQueueContext
    
    var initialShowLanguageSet = Set<Language>()
    var showLanguages = [Language]()
    var hideLanguages = [Language]()
    var messageBarButtonItem = MessageBarButtonItem()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = LocalizedStrings.LangFilter.languages
        
        showLanguages = Language.fetch(displayed: true, context: managedObjectContext)
        hideLanguages = Language.fetch(displayed: false, context: managedObjectContext)
        initialShowLanguageSet = Set(showLanguages)
        
        configureToolBar()
        configureSegmentedControls()
        
        sort()
    }
    
    override func viewWillDisappear(animated: Bool) {
        let hasChange = initialShowLanguageSet != Set(showLanguages)
        guard hasChange else {return}
        guard let libraryOnlineTBVC = self.navigationController?.topViewController as? LibraryOnlineTBVC else {return}
        libraryOnlineTBVC.refreshFetchedResultController()
    }
    
    // MARK: - Configure
    
    func configureToolBar() {
        navigationController?.toolbarHidden = false
        let spaceBarButtonItem = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace)
        setToolbarItems([spaceBarButtonItem, messageBarButtonItem, spaceBarButtonItem], animated: false)
        messageBarButtonItem.text = messageLabelText
    }
    
    func configureSegmentedControls() {
        sortSegmentedControl.selectedSegmentIndex = Preference.LangFilter.sortByAlphabeticalAsc == true ? 1: 0
        langNameSegmentedControl.selectedSegmentIndex = Preference.LangFilter.displayInOriginalLocale == true ? 1 : 0
        
        sortSegmentedControl.setTitle(LocalizedStrings.LangFilter.count, forSegmentAtIndex: 0)
        sortSegmentedControl.setTitle(LocalizedStrings.LangFilter.a_z, forSegmentAtIndex: 1)
        langNameSegmentedControl.setTitle(NSLocale.currentLocale().displayNameForKey(NSLocaleIdentifier, value: NSLocale.preferredLangCodes[0]), forSegmentAtIndex: 0)
        langNameSegmentedControl.setTitle(LocalizedStrings.LangFilter.original, forSegmentAtIndex: 1)
    }
    
    func sort() {
        if sortSegmentedControl.selectedSegmentIndex == 0 {
            showLanguages = sortByCountDesc(showLanguages)
            hideLanguages = sortByCountDesc(hideLanguages)
        } else {
            showLanguages = sortByAlphabeticalAsc(showLanguages)
            hideLanguages = sortByAlphabeticalAsc(hideLanguages)
        }
    }
    
    var messageLabelText: String? {
        let displayInOriginalLocale = Preference.LangFilter.displayInOriginalLocale
        let firstName = displayInOriginalLocale ? showLanguages[safe: 0]?.nameInOriginalLocale : showLanguages[safe: 0]?.nameInCurrentLocale
        let secondName = displayInOriginalLocale ? showLanguages[safe: 1]?.nameInOriginalLocale : showLanguages[safe: 1]?.nameInCurrentLocale
        
        switch showLanguages.count {
        case 0:
            return LocalizedStrings.LangFilter.noLangSelected
        case 1:
            guard let name = firstName else {return nil}
            return String(format: LocalizedStrings.LangFilter.oneLangSelected, name)
        case 2:
            guard let name0 = firstName else {return nil}
            guard let name1 = secondName else {return nil}
            return String(format: LocalizedStrings.LangFilter.twoLangSelected, name0, name1)
        default:
            return String(format: LocalizedStrings.LangFilter.someLangSelected, showLanguages.count)
        }
    }
    
    @IBAction func sortSegmentedControlChanged(sender: UISegmentedControl) {
        sort()
        tableView.reloadData()
        Preference.LangFilter.sortByAlphabeticalAsc = sender.selectedSegmentIndex == 1
    }
    
    @IBAction func langNameSegmentedControlChanged(sender: UISegmentedControl) {
        Preference.LangFilter.displayInOriginalLocale = sender.selectedSegmentIndex == 1
        if Preference.LangFilter.sortByAlphabeticalAsc { sort() }
        tableView.reloadData()
        messageBarButtonItem.text = messageLabelText
    }
    
    // MARK: - Sort 
    
    func sortByCountDesc(languages: [Language]) -> [Language] {
        return languages.sort { (language0, language1) -> Bool in
            guard let count0 = language0.books?.count,
                let count1 = language1.books?.count else {return false}
            guard count0 != count1 else {
                return alphabeticalAscCompare(language0: language0, language1: language1, byOriginalLocale: Preference.LangFilter.displayInOriginalLocale)
            }
            return count0 > count1
        }
    }
    
    func sortByAlphabeticalAsc(languages: [Language]) -> [Language] {
        return languages.sort({alphabeticalAscCompare(language0: $0, language1: $1, byOriginalLocale: Preference.LangFilter.displayInOriginalLocale)})
    }
    
    private func alphabeticalAscCompare(language0 language0: Language, language1: Language, byOriginalLocale: Bool) -> Bool {
        if byOriginalLocale {
            guard let name0 = language0.nameInOriginalLocale,
                let name1 = language1.nameInOriginalLocale else {return false}
            return name0.compare(name1) == .OrderedAscending
        } else {
            guard let name0 = language0.nameInCurrentLocale,
                let name1 = language1.nameInCurrentLocale else {return false}
            return name0.compare(name1) == .OrderedAscending
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
            configureCell(cell, atIndexPath: indexPath, language: showLanguages[indexPath.row])
        } else {
            configureCell(cell, atIndexPath: indexPath, language: hideLanguages[indexPath.row])
        }
        return cell
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath, language: Language) {
        cell.textLabel?.text = Preference.LangFilter.displayInOriginalLocale ? language.nameInOriginalLocale : language.nameInCurrentLocale
        cell.detailTextLabel?.text = language.books?.count.description
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if showLanguages.count == 0 {
            return section == 0 ? "" : NSLocalizedString("All", comment: "Language selection: table section title") + "       "
        } else {
            return section == 0 ? NSLocalizedString("SHOWING", comment: "Language selection: table section title") : NSLocalizedString("HIDING", comment: "Language selection: table section title")
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
    class LangFilter {
        private static let comment = "Library, Language Filter"
        class var languages: String {return NSLocalizedString("Languages", comment: comment)}
        class var noLangSelected: String {return NSLocalizedString("All languages will be displayed", comment: comment)}
        class var oneLangSelected: String {return NSLocalizedString("%@ is selected", comment: comment)}
        class var twoLangSelected: String {return NSLocalizedString("%@ and %@ are selected", comment: comment)}
        class var someLangSelected: String {return NSLocalizedString("%d languages are selected", comment: comment)}
        
        class var count: String {return NSLocalizedString("Count", comment: comment)}
        class var a_z: String {return NSLocalizedString("A-Z", comment: comment)}
        class var original: String {return NSLocalizedString("Original", comment: comment)}
    }
}
