//
//  SearchNoTextController.swift
//  Kiwix
//
//  Created by Chris Li on 1/19/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit
import CoreData


class SearchNoTextController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate {
    let tableView = UITableView(frame: .zero, style: .grouped)
    
    override func loadView() {
        view = tableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.register(TableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.register(RecentSearchTableViewCell.self, forCellReuseIdentifier: "RecentSearchCell")
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
    
    // MARK: - UITableViewDataSource & Delegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return fetchedResultController.sections?.first?.numberOfObjects ?? 0
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TableViewCell
            configure(cell: cell, indexPath: IndexPath(row: indexPath.row, section: 0))
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RecentSearchCell", for: indexPath) as! RecentSearchTableViewCell
            return cell
        }
    }
    
    func configure(cell: TableViewCell, indexPath: IndexPath, animated: Bool = false) {
        let book = fetchedResultController.object(at: indexPath)
        cell.titleLabel.text = book.title
        cell.detailLabel.text = [book.fileSizeDescription, book.dateDescription, book.articleCountDescription].flatMap({$0}).joined(separator: ", ")
        cell.thumbImageView.image = UIImage(data: book.favIcon ?? Data())
        cell.thumbImageView.contentMode = .scaleAspectFit
        cell.accessoryType = book.includeInSearch ? .checkmark : .none
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            guard let cell = cell as? RecentSearchTableViewCell else {return}
            cell.collectionView.dataSource = self
            cell.collectionView.delegate = self
            cell.collectionView.tag = indexPath.section
            
            cell.collectionView.reloadData()
            cell.collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return NSLocalizedString("Recent Search", comment: "")
        } else {
            return NSLocalizedString("Search Filter", comment: "")
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let book = fetchedResultController.object(at: IndexPath(item: indexPath.item, section: 0))
        book.includeInSearch = !book.includeInSearch
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - UICollectionViewDataSource & Delegate
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 20
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! RecentSearchCollectionViewCell
        cell.label.text = "\(indexPath)"
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let string = "\(indexPath)"
        let width = NSString(string: string).boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 24),
                                                         options: .usesLineFragmentOrigin,
                                                         attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 12)],
                                                         context: nil).size.width
        return CGSize(width: width.rounded(.down) + 20, height: 24)
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
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
            return
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else {return}
            tableView.insertRows(at: [newIndexPath], with: .fade)
        case .delete:
            guard let indexPath = indexPath else {return}
            tableView.deleteRows(at: [indexPath], with: .fade)
        case .update:
            guard let indexPath = indexPath, let cell = tableView.cellForRow(at: indexPath) as? TableViewCell else {return}
            configure(cell: cell, indexPath: indexPath, animated: true)
        case .move:
            guard let indexPath = indexPath, let newIndexPath = newIndexPath else {return}
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.insertRows(at: [newIndexPath], with: .fade)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
