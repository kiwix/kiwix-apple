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

class SearchFilterController: UIViewController, UITableViewDelegate, UITableViewDataSource,
                              UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout,
                              SearchNoTextControllerSectionHeaderDelegate {
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
    
    private var recentSearchTexts = [String]() {
        didSet {
            if recentSearchTexts.count == 0, let index = sections.firstIndex(of: .recentSearch) {
                tableView.beginUpdates()
                sections.remove(at: index)
                tableView.deleteSections(IndexSet([index]), with: .fade)
                tableView.endUpdates()
            } else if recentSearchTexts.count > 0, !sections.contains(.recentSearch) {
                tableView.beginUpdates()
                sections.insert(.recentSearch, at: 0)
                tableView.insertSections(IndexSet([0]), with: .none)
                tableView.endUpdates()
            } else if recentSearchTexts.count > 0, let index = sections.firstIndex(of: .recentSearch) {
                guard recentSearchTexts != oldValue else {return}
                tableView.reloadSections(IndexSet([index]), with: .none)
            }
        }
    }
    
    // MARK: - Overrides
    
    override func loadView() {
        view = tableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableView.automaticDimension
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.register(TableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.register(RecentSearchTableViewCell.self, forCellReuseIdentifier: "RecentSearchCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        recentSearchTexts = Defaults[.recentSearchTexts]
        configureChangeToken()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        changeToken = nil
    }
    
    // MARK: - Observer
    
    private func configureChangeToken() {
        changeToken = zimFiles?.observe({ (changes) in
            switch changes {
            case .update(_, let deletions, let insertions, let updates):
                guard let sectionIndex = self.sections.firstIndex(of: .searchFilter) else {return}
                self.tableView.beginUpdates()
                self.tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: sectionIndex) }), with: .fade)
                self.tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: sectionIndex) }), with: .fade)
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
    
    // MARK: - SearchNoTextControllerSectionHeaderDelegate
    
    func sectionHeaderButtonTapped(button: UIButton, section: SearchFilterController.Section) {
        switch section {
        case .recentSearch:
            Defaults[.recentSearchTexts] = []
            recentSearchTexts.removeAll()
        case .searchFilter:
            do {
                let database = try Realm(configuration: Realm.defaultConfig)
                try database.write {
                    zimFiles?.forEach({ (zimFile) in
                        guard !zimFile.includeInSearch else {return}
                        zimFile.includeInSearch = true
                    })
                }
            } catch {}
        }
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
        cell.thumbImageView.image = UIImage(data: zimFile.icon) ?? #imageLiteral(resourceName: "GenericZimFile")
        cell.thumbImageView.contentMode = .scaleAspectFit
        cell.accessoryType = zimFile.includeInSearch ? .checkmark : .none
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let text: String = {
            switch sections[section] {
            case .recentSearch:
                return NSLocalizedString("Recent Search", comment: "Search Interface")
            case .searchFilter:
                return NSLocalizedString("Search Filter", comment: "Search Interface")
            }
        }()
        let buttonText: String = {
            switch sections[section] {
            case .recentSearch:
                return NSLocalizedString("Clear", comment: "Clear Recent Search Texts")
            case .searchFilter:
                return NSLocalizedString("All", comment: "Select All Books in Search Filter")
            }
        }()
        let view = SectionHeaderView(text: text, buttonText: buttonText, section: sections[section])
        view.delegate = self
        return view
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if sections[indexPath.section] == .recentSearch {
            guard let cell = cell as? RecentSearchTableViewCell else {return}
            cell.collectionView.dataSource = self
            cell.collectionView.delegate = self
            cell.collectionView.tag = indexPath.section
            
            cell.collectionView.reloadData()
            cell.collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 50 : 30
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if sections[indexPath.section] == .searchFilter {
            guard let zimFile = zimFiles?[indexPath.row], let token = changeToken else {return}
            let includeInSearch = !zimFile.includeInSearch
            tableView.cellForRow(at: indexPath)?.accessoryType = includeInSearch ? .checkmark : .none
            do {
                let database = try Realm(configuration: Realm.defaultConfig)
                database.beginWrite()
                zimFile.includeInSearch = includeInSearch
                try database.commitWrite(withoutNotifying: [token])
            } catch {}
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - UICollectionViewDataSource & Delegate
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return recentSearchTexts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! RecentSearchCollectionViewCell
        cell.label.text = recentSearchTexts[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let string = recentSearchTexts[indexPath.row]
        let width = NSString(string: string).boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 24),
                                                          options: .usesLineFragmentOrigin,
                                                          attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)],
                                                          context: nil).size.width
        return CGSize(width: max(width.rounded(.down) + 20, 28), height: 24)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let searchText = recentSearchTexts[indexPath.row]
        if let controller = presentingViewController as? ContentViewController {
            controller.searchController.searchBar.text = searchText
        }
    }
    
    // MARK: - Type Definition
    
    enum Section { case recentSearch, searchFilter }
    
    class SectionHeaderView: UIStackView {
        private let label = UILabel()
        private let button = UIButton()
        private let section: Section
        weak var delegate: SearchNoTextControllerSectionHeaderDelegate?
        
        init(text: String, buttonText: String, section: Section) {
            self.section = section
            super.init(frame: .zero)
            label.text = text.uppercased()
            button.setTitle(buttonText, for: .normal)
            configure()
        }
        
        required init(coder: NSCoder) {
            self.section = .searchFilter
            super.init(coder: coder)
            configure()
        }
        
        private func configure() {
            label.font = UIFont.systemFont(ofSize: 13)
            label.setContentHuggingPriority(UILayoutPriority(rawValue: 250), for: .horizontal)

            button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
            button.setContentHuggingPriority(UILayoutPriority(rawValue: 251), for: .horizontal)
            button.addTarget(self, action: #selector(buttonTapped(button:)), for: .touchUpInside)
            
            if #available(iOS 13.0, *) {
                label.textColor = .secondaryLabel
                button.setTitleColor(.secondaryLabel, for: .normal)
            } else {
                label.textColor = .darkGray
                button.setTitleColor(.gray, for: .normal)
            }
            
            alignment = .bottom
            preservesSuperviewLayoutMargins = true
            isLayoutMarginsRelativeArrangement = true
            
            addArrangedSubview(label)
            addArrangedSubview(button)
            label.heightAnchor.constraint(equalTo: button.heightAnchor).isActive = true
        }
        
        @objc private func buttonTapped(button: UIButton) {
            delegate?.sectionHeaderButtonTapped(button: button, section: section)
        }
    }
}

// MARK: - Protocols

protocol SearchNoTextControllerSectionHeaderDelegate: class {
    func sectionHeaderButtonTapped(button: UIButton, section: SearchFilterController.Section)
}
