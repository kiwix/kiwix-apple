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
    typealias LanguageCode = String
    
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let sortBy: UISegmentedControl
    private let sortingModes: [SortingMode] = [.alphabetically, .byCount]
    
    private let zimFileCount: [LanguageCode: Int]
    private var visible: [LanguageCode]
    private var hidden: [LanguageCode]
    
    var dismissCallback: (() -> Void)?
    
    // MARK: - Overrides
    
    init() {
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            let codes = database.objects(ZimFile.self).distinct(by: ["languageCode"]).map({ $0.languageCode })
            zimFileCount = codes.reduce(into: [LanguageCode: Int]()) { (counts, code) in
                counts[code] = database.objects(ZimFile.self).filter("languageCode = %@", code).count
            }
        } catch { zimFileCount = [LanguageCode: Int]() }
        
        visible = Defaults[.libraryFilterLanguageCodes]
        hidden = Array(Set(zimFileCount.keys).subtracting(visible))
        
        let sortingMode = SortingMode(rawValue: Defaults[.libraryLanguageSortingMode]) ?? .alphabetically
        sortBy = UISegmentedControl(items: Array(sortingModes.map({ $0.localizedDescription }) ))
        sortBy.selectedSegmentIndex = sortingModes.firstIndex(of: sortingMode) ?? 0
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = tableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UIRightDetailTableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissController))
        navigationItem.titleView = sortBy
        sortBy.addTarget(self, action: #selector(sortByValueChanged(segmentedControl:)), for: .valueChanged)
        
        sortLanguageCodes(codes: &visible)
        sortLanguageCodes(codes: &hidden)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Defaults[.libraryFilterLanguageCodes] = visible
        dismissCallback?()
    }
    
    // MARK: -
    
    @objc func dismissController() {
        dismiss(animated: true, completion: nil)
    }
    
    private func sortLanguageCodes(codes: inout[LanguageCode]) {
        func compareLocalizedName(code0: LanguageCode, code1: LanguageCode) -> Bool {
            guard let name0 = Locale.current.localizedString(forLanguageCode: code0),
                let name1 = Locale.current.localizedString(forLanguageCode: code1) else {return false}
            return name0 < name1
        }
        
        switch sortingModes[sortBy.selectedSegmentIndex] {
        case .alphabetically:
            codes.sort { return compareLocalizedName(code0: $0, code1: $1) }
        case .byCount:
            codes.sort {
                if let count0 = zimFileCount[$0], let count1 = zimFileCount[$1], count0 != count1 {
                    return count0 > count1
                } else {
                    return compareLocalizedName(code0: $0, code1: $1)
                }
            }
        }
    }
    
    @objc func sortByValueChanged(segmentedControl: UISegmentedControl) {
        Defaults[.libraryLanguageSortingMode] = sortingModes[segmentedControl.selectedSegmentIndex].rawValue
        sortLanguageCodes(codes: &visible)
        sortLanguageCodes(codes: &hidden)
        tableView.reloadData()
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! UIRightDetailTableViewCell
        let code: String = {
            if indexPath.section == 0 {
                return visible[indexPath.row]
            } else {
                return hidden[indexPath.row]
            }
        }()
        cell.textLabel?.text = Locale.current.localizedString(forLanguageCode: code) ?? code
        cell.detailTextLabel?.text = "\(zimFileCount[code] ?? 0)"
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if visible.count == 0 {
            return section == 0 ? "" : NSLocalizedString("All", comment: "Library: Language Filter Section Header") + "        "
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
            sortLanguageCodes(codes: &hidden)
            
            guard let insertedRowIndex = hidden.index(of: language) else {tableView.reloadData(); return}
            let insertedIndexPath = IndexPath(row: insertedRowIndex, section: 1)
            animateUpdates(deleted: indexPath, inserted: insertedIndexPath)
        } else {
            let language = hidden[indexPath.row]
            visible.append(language)
            hidden.remove(at: indexPath.row)
            sortLanguageCodes(codes: &visible)
            
            guard let insertedRowIndex = visible.index(of: language) else {tableView.reloadData(); return}
            let insertedIndexPath = IndexPath(row: insertedRowIndex, section: 0)
            animateUpdates(deleted: indexPath, inserted: insertedIndexPath)
        }
    }
    
    // MARK: - Type Definition
    
    private enum SortingMode: String {
        case alphabetically, byCount
        
        var localizedDescription: String {
            switch self {
            case .alphabetically:
                return NSLocalizedString("A-Z", comment: "Library: Language Filter Sorting")
            case .byCount:
                return NSLocalizedString("By Count", comment: "Library: Language Filter Sorting")
            }
        }
    }
}
