//
//  LibraryLanguageController.swift
//  iOS
//
//  Created by Chris Li on 5/8/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit
import RealmSwift
import SwiftyUserDefaults

class LibraryLanguageController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let tableView = UITableView(frame: .zero, style: .grouped)
    
    private var visible = [String]()
    private var hidden = [String]()
    private var count = [String: Int]()
    var dismissCallback: ((_ visibleLanguageCode: [String]) -> Void)?
    
    // MARK: - Overrides
    
    override func loadView() {
        view = tableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(Cell.self, forCellReuseIdentifier: "Cell")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissController))
        populateLanguages()
        sortLanguagesByCountDescending(languages: &visible)
        sortLanguagesByCountDescending(languages: &hidden)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Defaults[.libraryFilterLanguageCodes] = visible
        dismissCallback?(visible)
    }
    
    // MARK: -
    
    @objc func dismissController() {
        dismiss(animated: true, completion: nil)
    }
    
    private func populateLanguages() {
        let visibleLanguageCodes = Defaults[.libraryFilterLanguageCodes]
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            let codes = database.objects(ZimFile.self).distinct(by: ["languageCode"]).map({ $0.languageCode })
            for code in codes {
                if visibleLanguageCodes.contains(code) {
                    visible.append(code)
                } else {
                    hidden.append(code)
                }
                self.count[code] = database.objects(ZimFile.self).filter("languageCode = %@", code).count
            }
        } catch { return }
    }
    
    private func sortLanguagesByCountDescending(languages: inout[String]) {
        languages.sort {
            if let count0 = count[$0], let count1 = count[$1], count0 != count1 {
                return count0 > count1
            } else {
                guard let name0 = Locale.current.localizedString(forLanguageCode: $0),
                    let name1 = Locale.current.localizedString(forLanguageCode: $1) else {return false}
                return name0 < name1
            }
        }
    }
    
    // MARK: - UITableViewDataSource & Delegates
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return visible.count
        } else {
            return hidden.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! Cell
        let code: String = {
            if indexPath.section == 0 {
                return visible[indexPath.row]
            } else {
                return hidden[indexPath.row]
            }
        }()
        cell.textLabel?.text = Locale.current.localizedString(forLanguageCode: code) ?? code
        cell.detailTextLabel?.text = "\(count[code] ?? 0)"
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if visible.count == 0 {
            return section == 0 ? "" : NSLocalizedString("All", comment: "Library Language Filter Section Header") + "        "
        } else {
            return section == 0 ? NSLocalizedString("Showing", comment: "Library Language Filter Section Header")
                : NSLocalizedString("Hiding", comment: "Library Language Filter Section Header")
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        func animateUpdates(deleted: IndexPath, inserted: IndexPath) {
            tableView.beginUpdates()
            tableView.deleteRows(at: [deleted], with: .right)
            tableView.insertRows(at: [inserted], with: .right)
            tableView.headerView(forSection: 0)?.textLabel?.text = self.tableView(tableView, titleForHeaderInSection: 0)?.uppercased()
            tableView.headerView(forSection: 1)?.textLabel?.text = self.tableView(tableView, titleForHeaderInSection: 1)?.uppercased()
            tableView.endUpdates()
        }
        
        if indexPath.section == 0 {
            let language = visible[indexPath.row]
            hidden.append(language)
            visible.remove(at: indexPath.row)
            sortLanguagesByCountDescending(languages: &hidden)
            
            guard let insertedRowIndex = hidden.index(of: language) else {tableView.reloadData(); return}
            let insertedIndexPath = IndexPath(row: insertedRowIndex, section: 1)
            animateUpdates(deleted: indexPath, inserted: insertedIndexPath)
        } else {
            let language = hidden[indexPath.row]
            visible.append(language)
            hidden.remove(at: indexPath.row)
            sortLanguagesByCountDescending(languages: &visible)
            
            guard let insertedRowIndex = visible.index(of: language) else {tableView.reloadData(); return}
            let insertedIndexPath = IndexPath(row: insertedRowIndex, section: 0)
            animateUpdates(deleted: indexPath, inserted: insertedIndexPath)
        }
    }
    
    // MARK: -
    
    private class Cell: UITableViewCell {
        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
