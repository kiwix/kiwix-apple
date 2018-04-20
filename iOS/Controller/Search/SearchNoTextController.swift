//
//  SearchNoTextController.swift
//  Kiwix
//
//  Created by Chris Li on 1/19/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit
import RealmSwift
import SwiftyUserDefaults

class SearchNoTextController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private var sections: [Section] = [.searchFilter]
    
    private let zimFiles: Results<ZimFile>? = {
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            let predicate = NSPredicate(format: "stateRaw == %@", ZimFile.State.local.rawValue)
            return database.objects(ZimFile.self).filter(predicate)
        } catch { return nil }
    }()
    private var changeToken: NotificationToken?
    
    // MARK: - Overrides
    
    override func loadView() {
        view = tableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.register(TableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.register(RecentSearchTableViewCell.self, forCellReuseIdentifier: "RecentSearchCell")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureDatabase()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass else {return}
        switch traitCollection.horizontalSizeClass {
        case .compact:
            tableView.backgroundColor = .groupTableViewBackground
        case .regular:
            tableView.backgroundColor = .clear
        case .unspecified:
            break
        }
    }
    
    // MARK: - Database
    
    func configureDatabase() {
        changeToken = zimFiles?.observe({ (changes) in
            switch changes {
            case .initial:
                self.tableView.reloadData()
            case .update(_, let deletions, let insertions, let updates):
                guard let sectionIndex = self.sections.index(of: .searchFilter) else {return}
                self.tableView.beginUpdates()
                self.tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: sectionIndex) }), with: .automatic)
                self.tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: sectionIndex) }), with: .automatic)
                updates.forEach({ (row) in
                    let indexPath = IndexPath(row: row, section: sectionIndex)
                    guard let cell = self.tableView.cellForRow(at: indexPath) as? TableViewCell else {return}
                    self.configure(cell: cell, indexPath: indexPath)
                })
                self.tableView.endUpdates()
            default:
                break
            }
        })
    }
    
    // MARK: - UITableViewDataSource & Delegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if sections[section] == .searchFilter {
            return zimFiles?.count ?? 0
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if sections[indexPath.section] == .searchFilter {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TableViewCell
            configure(cell: cell, indexPath: IndexPath(row: indexPath.row, section: 0))
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RecentSearchCell", for: indexPath) as! RecentSearchTableViewCell
            return cell
        }
    }
    
    func configure(cell: TableViewCell, indexPath: IndexPath) {
        guard let zimFile = zimFiles?[indexPath.row] else {return}
        cell.titleLabel.text = zimFile.title
        cell.detailLabel.text = [zimFile.fileSizeDescription, zimFile.creationDateDescription, zimFile.articleCountDescription].joined(separator: ", ")
        cell.thumbImageView.image = UIImage(data: zimFile.icon)
        cell.thumbImageView.contentMode = .scaleAspectFit
        cell.accessoryType = zimFile.includeInSearch ? .checkmark : .none
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if sections[indexPath.section] == .searchFilter {
            guard let zimFile = zimFiles?[indexPath.row], let token = changeToken else {return}
            let includeInSearch = !zimFile.includeInSearch
            tableView.cellForRow(at: indexPath)?.accessoryType = includeInSearch ? .checkmark : .none
            do {
                let database = try Realm()
                database.beginWrite()
                zimFile.includeInSearch = includeInSearch
                try database.commitWrite(withoutNotifying: [token])
            } catch {}
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Type Definition
    
    enum Section { case recentSearch, searchFilter }
}
