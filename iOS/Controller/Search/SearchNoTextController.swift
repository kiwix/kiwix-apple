//
//  SearchNoTextController.swift
//  Kiwix
//
//  Created by Chris Li on 1/19/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit
import CoreData
import SwiftyUserDefaults

class SearchNoTextController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate {
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private var sections: [SearchNoTextControllerSections] = [.searchFilter]
    private var recentSearchTexts = Defaults[.recentSearchTexts] {
        didSet {
            Defaults[.recentSearchTexts] = recentSearchTexts
            if recentSearchTexts.count == 0, let index = sections.index(of: .recentSearch) {
                tableView.beginUpdates()
                sections.remove(at: index)
                tableView.deleteSections(IndexSet([index]), with: .fade)
                tableView.endUpdates()
            } else if recentSearchTexts.count > 0 && !sections.contains(.recentSearch) {
                tableView.beginUpdates()
                sections.insert(.recentSearch, at: 0)
                tableView.insertSections(IndexSet([0]), with: .none)
                tableView.endUpdates()
            } else if recentSearchTexts.count > 0, let index = sections.index(of: .recentSearch) {
                guard recentSearchTexts != oldValue else {return}
                tableView.reloadSections(IndexSet([index]), with: .none)
            }
        }
    }
    
    var localBookIDs: Set<ZimFileID> {
        let books = fetchedResultController.fetchedObjects ?? [Book]()
        return Set(books.map({ $0.id }))
    }
    var includedInSearchBookIDs: Set<ZimFileID> {
        let books = fetchedResultController.fetchedObjects ?? [Book]()
        return Set(books.filter({ $0.includeInSearch }).map({ $0.id }))
    }
    
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
        if recentSearchTexts.count > 0 {
            sections.insert(.recentSearch, at: 0)
        }
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
    
    func add(recentSearchText: String) {
        /* we make a local copy of `recentSearchTexts` to prevent tableView operations
         being triggered too many times during update of search texts */
        var searchTexts = recentSearchTexts
        if let index = searchTexts.index(of: recentSearchText) {
            searchTexts.remove(at: index)
        }
        searchTexts.insert(recentSearchText, at: 0)
        if searchTexts.count > 20 {
            searchTexts = Array(recentSearchTexts[..<20])
        }
        recentSearchTexts = searchTexts
    }
    
    @objc private func buttonTapped(button: SectionHeaderButton) {
        guard let section = button.section else {return}
        switch section {
        case .recentSearch:
            recentSearchTexts.removeAll()
        case .searchFilter:
            fetchedResultController.fetchedObjects?.forEach({ $0.includeInSearch = true })
        }
    }
    
    // MARK: - UITableViewDataSource & Delegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if sections[section] == .searchFilter {
            return fetchedResultController.sections?.first?.numberOfObjects ?? 0
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
    
    func configure(cell: TableViewCell, indexPath: IndexPath, animated: Bool = false) {
        let book = fetchedResultController.object(at: IndexPath(row: indexPath.row, section: 0))
        cell.titleLabel.text = book.title
        cell.detailLabel.text = [book.fileSizeDescription, book.dateDescription, book.articleCountDescription].flatMap({$0}).joined(separator: ", ")
        cell.thumbImageView.image = UIImage(data: book.favIcon ?? Data())
        cell.thumbImageView.contentMode = .scaleAspectFit
        cell.accessoryType = book.includeInSearch ? .checkmark : .none
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
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        let labelText: String = {
            switch sections[section] {
            case .recentSearch:
                return NSLocalizedString("Recent Search", comment: "Search Interface")
            case .searchFilter:
                return NSLocalizedString("Search Filter", comment: "Search Interface")
            }
        }()
        label.text = labelText.uppercased()
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = UIColor.darkGray
        label.setContentHuggingPriority(UILayoutPriority(rawValue: 250), for: .horizontal)
        
        let button = SectionHeaderButton(section: sections[section])
        let buttonText: String = {
            switch sections[section] {
            case .recentSearch:
                return NSLocalizedString("Clear", comment: "Clear Recent Search Texts")
            case .searchFilter:
                return NSLocalizedString("All", comment: "Select All Books in Search Filter")
            }
        }()
        button.setTitle(buttonText, for: .normal)
        button.setTitleColor(UIColor.gray, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setContentHuggingPriority(UILayoutPriority(rawValue: 251), for: .horizontal)
        button.addTarget(self, action: #selector(buttonTapped(button:)), for: .touchUpInside)
        
        let stackView = UIStackView()
        stackView.alignment = .bottom
        stackView.preservesSuperviewLayoutMargins = true
        stackView.isLayoutMarginsRelativeArrangement = true
        
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(button)
        label.heightAnchor.constraint(equalTo: button.heightAnchor).isActive = true
        
        return stackView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 50 : 30
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if sections[indexPath.section] == .searchFilter {
            let book = fetchedResultController.object(at: IndexPath(item: indexPath.item, section: 0))
            book.includeInSearch = !book.includeInSearch
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
                                                         attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 12)],
                                                         context: nil).size.width
        return CGSize(width: width.rounded(.down) + 20, height: 24)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let searchText = recentSearchTexts[indexPath.row]
        if let main = presentingViewController as? MainController {
            main.searchController.searchBar.text = searchText
        }
    }
    
    // MARK: - NSFetchedResultsController
    
    private let managedObjectContext = CoreDataContainer.shared.viewContext
    private lazy var fetchedResultController: NSFetchedResultsController<Book> = {
        let fetchRequest = Book.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Book.title, ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "stateRaw == %d", BookState.local.rawValue)
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                    managedObjectContext: self.managedObjectContext,
                                                    sectionNameKeyPath: nil, cacheName: nil)
        controller.delegate = self
        try? controller.performFetch()
        return controller as! NSFetchedResultsController<Book>
    }()
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard let sectionIndex = sections.index(of: .searchFilter) else {return}
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else {return}
            tableView.insertRows(at: [IndexPath(row: newIndexPath.row, section: sectionIndex)], with: .fade)
        case .delete:
            guard let indexPath = indexPath else {return}
            tableView.deleteRows(at: [IndexPath(row: indexPath.row, section: sectionIndex)], with: .fade)
        case .update:
            guard let indexPath = indexPath, let cell = tableView.cellForRow(at: IndexPath(row: indexPath.row, section: sectionIndex)) as? TableViewCell else {return}
            configure(cell: cell, indexPath: IndexPath(row: indexPath.row, section: sectionIndex), animated: true)
        case .move:
            guard let indexPath = indexPath, let newIndexPath = newIndexPath else {return}
            tableView.deleteRows(at: [IndexPath(row: indexPath.row, section: sectionIndex)], with: .fade)
            tableView.insertRows(at: [IndexPath(row: newIndexPath.row, section: sectionIndex)], with: .fade)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
        (parent as? SearchResultController)?.configureVisiualViewContent(mode: nil)
    }
}

private class SectionHeaderButton: UIButton {
    private(set) var section: SearchNoTextControllerSections? = nil
    convenience init(section: SearchNoTextControllerSections) {
        self.init(frame: .zero)
        self.section = section
    }
}

enum SearchNoTextControllerSections {
    case recentSearch, searchFilter
}
