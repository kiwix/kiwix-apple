//
//  LibraryLanguageController.swift
//  Kiwix
//
//  Created by Chris Li on 1/24/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import CoreData
import DZNEmptyDataSet

class LibraryLanguageController: UITableViewController, NSFetchedResultsControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

    @IBOutlet weak var langNameSegmentedControl: UISegmentedControl!
    @IBAction func segmentedControlChanged(_ sender: UISegmentedControl) {
        Preference.LangFilter.displayInOriginalLocale = !Preference.LangFilter.displayInOriginalLocale
        tableView.reloadRows(at: tableView.indexPathsForVisibleRows ?? [IndexPath](), with: .automatic)
    }
    @IBAction func doneButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    private let managedObjectContext = AppDelegate.persistentContainer.viewContext
    private var initialShowLanguageSet = Set<Language>()
    private var showLanguages = [Language]()
    private var hideLanguages = [Language]()
    var dismissBlock: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        showLanguages = Language.fetch(displayed: true, context: managedObjectContext)
        hideLanguages = Language.fetch(displayed: false, context: managedObjectContext)
        initialShowLanguageSet = Set(showLanguages)
        
        configureSegmentedControls()
        sort()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dismissBlock?()
    }
    
    func configureSegmentedControls() {
        langNameSegmentedControl.selectedSegmentIndex = Preference.LangFilter.displayInOriginalLocale == true ? 1 : 0
        langNameSegmentedControl.setTitle((Locale.current as NSLocale).displayName(forKey: NSLocale.Key.identifier, value: Locale.preferredLangCodes[0]), forSegmentAt: 0)
        langNameSegmentedControl.setTitle(Localized.Library.LanguageFilter.original, forSegmentAt: 1)
    }
    
    // MARK: - Sort
    
    func sort() {
        showLanguages = sortByCountDesc(languages: showLanguages)
        hideLanguages = sortByCountDesc(languages: hideLanguages)
    }
    
    func sortByCountDesc(languages: [Language]) -> [Language] {
        return languages.sorted { (language0, language1) -> Bool in
            let count0 = language0.books.count
            let count1 = language1.books.count
            guard count0 != count1 else {
                return alphabeticalAscCompare(language0: language0, language1: language1,
                                              byOriginalLocale: Preference.LangFilter.displayInOriginalLocale)
            }
            return count0 > count1
        }
    }
    
    private func alphabeticalAscCompare(language0: Language, language1: Language, byOriginalLocale: Bool) -> Bool {
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
            return section == 0 ? "" : Localized.Library.LanguageFilter.all + "       "
        } else {
            return section == 0 ? Localized.Library.LanguageFilter.showing : Localized.Library.LanguageFilter.hiding
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
            hideLanguages = sortByCountDesc(languages: hideLanguages)
            
            guard let row = hideLanguages.index(of: language) else {tableView.reloadData(); return}
            let destinationIndexPath = IndexPath(row: row, section: 1)
            animateUpdates(indexPath, destinationIndexPath: destinationIndexPath)
        } else {
            let language = hideLanguages[indexPath.row]
            language.isDisplayed = true
            showLanguages.append(language)
            hideLanguages.remove(at: indexPath.row)
            showLanguages = sortByCountDesc(languages: showLanguages)
            
            guard let row = showLanguages.index(of: language) else {tableView.reloadData(); return}
            let destinationIndexPath = IndexPath(row: row, section: 0)
            animateUpdates(indexPath, destinationIndexPath: destinationIndexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return showLanguages.count == 0 ? CGFloat.leastNormalMagnitude : 44
        } else {
            return 30
        }
    }
}

extension Localized.Library {
    class LanguageFilter {
        static let title = NSLocalizedString("Languages", comment: "Library, Language Filter")
        static let all = NSLocalizedString("ALL", comment: "Library, Language Filter")
        static let showing = NSLocalizedString("SHOWING", comment: "Library, Language Filter")
        static let hiding = NSLocalizedString("HIDING", comment: "Library, Language Filter")
        static let original = NSLocalizedString("Original", comment: "Library, Language Filter")
    }
}
