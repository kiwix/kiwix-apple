//
//  LibraryLanguageController.swift
//  Kiwix
//
//  Created by Chris Li on 10/18/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class LibraryLanguageController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let tableView = UITableView(frame: .zero, style: .grouped)
    let segmentedControl = UISegmentedControl(items: [(Locale.current as NSLocale).displayName(forKey: .identifier, value: Locale.preferredLanguages[0])!,
                                                      NSLocalizedString("Original", comment: "Language lanuguage filter display name control")])
    
    private let managedObjectContext = CoreDataContainer.shared.viewContext
    private var initialShowLanguageSet = Set<Language>()
    private var showLanguages = [Language]()
    private var hideLanguages = [Language]()
    var dismissBlock: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureSegmentedControls()
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissController))
        
        showLanguages = Language.fetch(displayed: true, context: managedObjectContext)
        hideLanguages = Language.fetch(displayed: false, context: managedObjectContext)
        initialShowLanguageSet = Set(showLanguages)
        sort()
    }
    
    override func loadView() {
        view = tableView
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dismissBlock?()
    }
    
    private func configureSegmentedControls() {
        let stackView = UIStackView()
        segmentedControl.apportionsSegmentWidthsByContent = true
        segmentedControl.selectedSegmentIndex = Preference.LangFilter.displayInOriginalLocale == true ? 1 : 0
        segmentedControl.addTarget(self, action: #selector(segmentedControlChanged(sender:)), for: .valueChanged)
        segmentedControl.setContentHuggingPriority(.init(251), for: .horizontal)
        stackView.addArrangedSubview(segmentedControl)
        stackView.addArrangedSubview(UIView())
        navigationItem.titleView = segmentedControl
    }
    
    @objc func segmentedControlChanged(sender: UISegmentedControl) {
        Preference.LangFilter.displayInOriginalLocale = !Preference.LangFilter.displayInOriginalLocale
        tableView.reloadRows(at: tableView.indexPathsForVisibleRows ?? [IndexPath](), with: .automatic)
    }
    
    @objc func dismissController() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Sort
    
    private func sort() {
        showLanguages = sortByCountDesc(languages: showLanguages)
        hideLanguages = sortByCountDesc(languages: hideLanguages)
    }
    
    private func sortByCountDesc(languages: [Language]) -> [Language] {
        return languages.sorted {
            let count0 = $0.books.count
            let count1 = $1.books.count
            guard $0.books.count != $1.books.count else {
                if Preference.LangFilter.displayInOriginalLocale {
                    guard let name0 = $0.nameInOriginalLocale,
                        let name1 = $1.nameInOriginalLocale else {return false}
                    return name0.compare(name1) == .orderedAscending
                } else {
                    guard let name0 = $0.nameInCurrentLocale,
                        let name1 = $1.nameInCurrentLocale else {return false}
                    return name0.compare(name1) == .orderedAscending
                }
            }
            return count0 > count1
        }
    }

    // MARK: - UITableViewDataSource & Delegates

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? showLanguages.count : hideLanguages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: "Cell")
        if indexPath.section == 0 {
            configure(cell: cell, atIndexPath: indexPath, language: showLanguages[indexPath.row])
        } else {
            configure(cell: cell, atIndexPath: indexPath, language: hideLanguages[indexPath.row])
        }
        return cell
    }
    
    func configure(cell: UITableViewCell, atIndexPath indexPath: IndexPath, language: Language) {
        cell.textLabel?.text = Preference.LangFilter.displayInOriginalLocale ? language.nameInOriginalLocale : language.nameInCurrentLocale
        cell.detailTextLabel?.text = language.books.count.description
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if showLanguages.count == 0 {
            return section == 0 ? "" : "All" + "       "
        } else {
            return section == 0 ? "Showing" : "Hiding"
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        func animateUpdates(_ originalIndexPath: IndexPath, destinationIndexPath: IndexPath) {
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .right)
            tableView.insertRows(at: [destinationIndexPath], with: .right)
            tableView.headerView(forSection: 0)?.textLabel?.text = self.tableView(tableView, titleForHeaderInSection: 0)?.uppercased()
            tableView.headerView(forSection: 1)?.textLabel?.text = self.tableView(tableView, titleForHeaderInSection: 1)?.uppercased()
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
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if showLanguages.count == 0 {
            return section == 0 ? CGFloat.leastNormalMagnitude : 36
        } else {
            return 36
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

}
