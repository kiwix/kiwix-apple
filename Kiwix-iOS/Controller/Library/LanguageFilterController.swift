//
//  LanguageFilterController.swift
//  Kiwix
//
//  Created by Chris Li on 8/22/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import CoreData
import DZNEmptyDataSet

class LanguageFilterController: UITableViewController, NSFetchedResultsControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    @IBOutlet weak var sortSegmentedControl: UISegmentedControl!
    @IBOutlet weak var langNameSegmentedControl: UISegmentedControl!
    
    fileprivate let managedObjectContext = NSManagedObjectContext.mainQueueContext
    
    weak var delegate: LanguageFilterUpdating?
    fileprivate var initialShowLanguageSet = Set<Language>()
    fileprivate var showLanguages = [Language]()
    fileprivate var hideLanguages = [Language]()
    fileprivate var messageBarButtonItem = MessageBarButtonItem()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Languages", comment: "Library, Language Filter")
        
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.tableFooterView = UIView()
        
        showLanguages = Language.fetch(displayed: true, context: managedObjectContext)
        hideLanguages = Language.fetch(displayed: false, context: managedObjectContext)
        initialShowLanguageSet = Set(showLanguages)
        
        configureToolBar()
        configureSegmentedControls()
        
        sort()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        let hasChange = initialShowLanguageSet != Set(showLanguages)
        if hasChange {_ = try? managedObjectContext.save()}
        delegate?.languageFilterFinsihEditing(hasChange)
    }
    
    // MARK: - Configure
    
    func configureToolBar() {
        navigationController?.isToolbarHidden = false
        let spaceBarButtonItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace)
        setToolbarItems([spaceBarButtonItem, messageBarButtonItem, spaceBarButtonItem], animated: false)
        messageBarButtonItem.text = messageLabelText
    }
    
    func configureSegmentedControls() {
        sortSegmentedControl.selectedSegmentIndex = Preference.LangFilter.sortByAlphabeticalAsc == true ? 1: 0
        langNameSegmentedControl.selectedSegmentIndex = Preference.LangFilter.displayInOriginalLocale == true ? 1 : 0
        
        sortSegmentedControl.setTitle(NSLocalizedString("Count", comment: "Library, Language Filter"), forSegmentAt: 0)
        sortSegmentedControl.setTitle(NSLocalizedString("A-Z", comment: "Library, Language Filter"), forSegmentAt: 1)
        langNameSegmentedControl.setTitle((Locale.current as NSLocale).displayName(forKey: NSLocale.Key.identifier, value: Locale.preferredLangCodes[0]), forSegmentAt: 0)
        langNameSegmentedControl.setTitle(NSLocalizedString("Original", comment: "Library, Language Filter"), forSegmentAt: 1)
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
            return NSLocalizedString("All languages will be displayed", comment: "Library, Language Filter")
        case 1:
            guard let name = firstName else {return nil}
            return String(format: NSLocalizedString("%@ is selected", comment: "Library, Language Filter"), name)
        case 2:
            guard let name0 = firstName else {return nil}
            guard let name1 = secondName else {return nil}
            return String(format: NSLocalizedString("%@ and %@ are selected", comment: "Library, Language Filter"), name0, name1)
        default:
            return String(format: NSLocalizedString("%d languages are selected", comment: "Library, Language Filter"), showLanguages.count)
        }
    }
    
    @IBAction func sortSegmentedControlChanged(_ sender: UISegmentedControl) {
        sort()
        tableView.reloadData()
        Preference.LangFilter.sortByAlphabeticalAsc = sender.selectedSegmentIndex == 1
    }
    
    @IBAction func langNameSegmentedControlChanged(_ sender: UISegmentedControl) {
        Preference.LangFilter.displayInOriginalLocale = sender.selectedSegmentIndex == 1
        if Preference.LangFilter.sortByAlphabeticalAsc { sort() }
        tableView.reloadData()
        messageBarButtonItem.text = messageLabelText
    }
    
    // MARK: - Sort 
    
    func sortByCountDesc(_ languages: [Language]) -> [Language] {
        return languages.sorted { (language0, language1) -> Bool in
            let count0 = language0.books.count
            let count1 = language1.books.count
            guard count0 != count1 else {
                return alphabeticalAscCompare(language0: language0, language1: language1, byOriginalLocale: Preference.LangFilter.displayInOriginalLocale)
            }
            return count0 > count1
        }
    }
    
    func sortByAlphabeticalAsc(_ languages: [Language]) -> [Language] {
        return languages.sorted(by: {alphabeticalAscCompare(language0: $0, language1: $1, byOriginalLocale: Preference.LangFilter.displayInOriginalLocale)})
    }
    
    fileprivate func alphabeticalAscCompare(language0: Language, language1: Language, byOriginalLocale: Bool) -> Bool {
        if byOriginalLocale {
            guard let name0 = language0.nameInOriginalLocale,
                let name1 = language1.nameInOriginalLocale else {return false}
            return name0.compare(name1) == .orderedAscending
        } else {
            guard let name0 = language0.nameInCurrentLocale,
                let name1 = language1.nameInCurrentLocale else {return false}
            return name0.compare(name1) == .orderedAscending
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? showLanguages.count : hideLanguages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        if indexPath.section == 0 {
            configureCell(cell, atIndexPath: indexPath, language: showLanguages[indexPath.row])
        } else {
            configureCell(cell, atIndexPath: indexPath, language: hideLanguages[indexPath.row])
        }
        return cell
    }
    
    func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath, language: Language) {
        cell.textLabel?.text = Preference.LangFilter.displayInOriginalLocale ? language.nameInOriginalLocale : language.nameInCurrentLocale
        cell.detailTextLabel?.text = language.books.count.description
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if showLanguages.count == 0 {
            return section == 0 ? "" : NSLocalizedString("ALL", comment: "Language selection: table section title") + "       "
        } else {
            return section == 0 ? NSLocalizedString("SHOWING", comment: "Language selection: table section title") : NSLocalizedString("HIDING", comment: "Language selection: table section title")
        }
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        func animateUpdates(_ originalIndexPath: IndexPath, destinationIndexPath: IndexPath) {
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .right)
            tableView.insertRows(at: [destinationIndexPath], with: .right)
            tableView.headerView(forSection: 0)?.textLabel?.text = self.tableView(tableView, titleForHeaderInSection: 0)
            tableView.headerView(forSection: 1)?.textLabel?.text = self.tableView(tableView, titleForHeaderInSection: 1)
            tableView.endUpdates()
        }
        
        if indexPath.section == 0 {
            let language = showLanguages[indexPath.row]
            language.isDisplayed = false
            hideLanguages.append(language)
            showLanguages.remove(at: indexPath.row)
            hideLanguages = sortByCountDesc(hideLanguages)
            
            guard let row = hideLanguages.index(of: language) else {tableView.reloadData(); return}
            let destinationIndexPath = IndexPath(row: row, section: 1)
            animateUpdates(indexPath, destinationIndexPath: destinationIndexPath)
        } else {
            let language = hideLanguages[indexPath.row]
            language.isDisplayed = true
            showLanguages.append(language)
            hideLanguages.remove(at: indexPath.row)
            showLanguages = sortByCountDesc(showLanguages)
            
            guard let row = showLanguages.index(of: language) else {tableView.reloadData(); return}
            let destinationIndexPath = IndexPath(row: row, section: 0)
            animateUpdates(indexPath, destinationIndexPath: destinationIndexPath)
        }
        
        messageBarButtonItem.text = messageLabelText
        delegate?.languageFilterChanged()
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if showLanguages.count == 0 && section == 0 {return CGFloat.leastNormalMagnitude}
        return tableView.sectionHeaderHeight
    }
}

protocol LanguageFilterUpdating: class {
    func languageFilterChanged()
    func languageFilterFinsihEditing(_ hasChanges: Bool)
}
