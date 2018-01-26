//
//  BookmarkController.swift
//  iOS
//
//  Created by Chris Li on 1/24/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit
import CoreData

class BookmarkController: UITableViewController, NSFetchedResultsControllerDelegate {
    weak var delegate: BookmarkControllerDelegate? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Bookmarks", comment: "Bookmark view title")
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissController))
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.register(TableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        try? fetchedResultController.performFetch()
        tableView.reloadData()
        configureEmptyContentView()
    }
    
    @objc func dismissController() {
        dismiss(animated: true, completion: nil)
    }
    
    private func configureEmptyContentView() {
        if let numberOfArticles = fetchedResultController.sections?.first?.numberOfObjects, numberOfArticles > 0 {
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
        } else {
            tableView.separatorStyle = .none
            // have to delay a bit, since when tableview's last row is removed, we need to wait for the
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let emptyContentView = EmptyContentView(
                    image: #imageLiteral(resourceName: "StarColor"),
                    title: NSLocalizedString("Bookmark your favorite articles", comment: "Help message when there's no bookmark to show"),
                    subtitle: NSLocalizedString("To add, long press the star button on the tool bar.", comment: "Help message when there's no bookmark to show"))
                self.tableView.backgroundView = emptyContentView
            }
        }
    }
    
    // MARK: - UITableViewDataSource & Delagate
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultController.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultController.sections?[section].numberOfObjects ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TableViewCell
        configure(cell: cell, indexPath: indexPath)
        return cell
    }
    
    func configure(cell: UITableViewCell, indexPath: IndexPath, animated: Bool = false) {
        let article = fetchedResultController.object(at: indexPath)
        cell.textLabel?.text = article.snippet
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.text = article.snippet
        cell.backgroundColor = .clear
    }
    
    func configure(cell: TableViewCell, indexPath: IndexPath, animated: Bool = false) {
        let article = fetchedResultController.object(at: indexPath)
        cell.titleLabel.text = article.title
        cell.detailLabel.text = article.snippet
        cell.backgroundColor = .clear
        if let data = article.thumbnailData {
            cell.thumbImageView.image = UIImage(data: data)
            cell.thumbImageView.contentMode = .scaleAspectFill
        } else {
            cell.thumbImageView.image = UIImage(data: article.book?.favIcon ?? Data())
            cell.thumbImageView.contentMode = .scaleAspectFit
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let url = fetchedResultController.object(at: indexPath).url else {return}
        delegate?.didTapBookmark(articleURL: url)
        dismiss(animated: true) {
            tableView.deselectRow(at: indexPath, animated: false)
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let context = CoreDataContainer.shared.viewContext
            context.perform {
                context.delete(self.fetchedResultController.object(at: indexPath))
            }
        }
    }
    
    // MARK: - NSFetchedResultsController
    
    private let managedObjectContext = CoreDataContainer.shared.viewContext
    private lazy var fetchedResultController: NSFetchedResultsController<Article> = {
        let fetchRequest = Article.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "bookmarkDate", ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "isBookmarked == true")
        fetchRequest.fetchBatchSize = 20
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                    managedObjectContext: self.managedObjectContext,
                                                    sectionNameKeyPath: nil, cacheName: nil)
        controller.delegate = self
        return controller as! NSFetchedResultsController<Article>
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
            guard let indexPath = indexPath, let cell = tableView.cellForRow(at: indexPath) as? TableViewCell, tableView.visibleCells.contains(cell) else {return}
            configure(cell: cell, indexPath: indexPath, animated: true)
        case .move:
            guard let indexPath = indexPath, let newIndexPath = newIndexPath else {return}
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.insertRows(at: [newIndexPath], with: .fade)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
        configureEmptyContentView()
    }
}

protocol BookmarkControllerDelegate: class {
    func didTapBookmark(articleURL: URL)
}
