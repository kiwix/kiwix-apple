//
//  BookmarkViewController.swift
//  iOS
//
//  Created by Chris Li on 1/24/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit
import CoreData

class BookmarkViewController: BaseController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate {
    
    let tableView = UITableView()
    let emptyBackgroundView = BackgroundStackView(
        image: #imageLiteral(resourceName: "StarColor"),
        title: NSLocalizedString("Bookmark your favorite articles", comment: "Help message when there's no bookmark to show"),
        subtitle: NSLocalizedString("To add, long press the star button on the tool bar.", comment: "Help message when there's no bookmark to show"))
    weak var delegate: BookmarkControllerDelegate? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Bookmarks", comment: "Bookmark view title")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.register(TableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configure()
        tableView.setNeedsDisplay()
    }
    
    func configure() {
        if let numberOfArticles = fetchedResultController.sections?.first?.numberOfObjects, numberOfArticles > 0 {
            configure(tableView: tableView)
        } else {
            configure(stackView: emptyBackgroundView)
        }
    }
    
    // MARK: - UITableViewDataSource & Delagate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultController.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultController.sections?[section].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TableViewCell
        configure(bookCell: cell, indexPath: indexPath)
        return cell
    }
    
    func configure(bookCell cell: TableViewCell, indexPath: IndexPath, animated: Bool = false) {
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let article = fetchedResultController.object(at: indexPath)
        guard let url = article.url else {return}
        delegate?.didTapBookmark(articleURL: url)
        dismiss(animated: true) {
            tableView.deselectRow(at: indexPath, animated: false)
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
        try? controller.performFetch()
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
            guard let indexPath = indexPath, let cell = tableView.cellForRow(at: indexPath) as? TableViewCell else {return}
            configure(bookCell: cell, indexPath: indexPath, animated: true)
        case .move:
            guard let indexPath = indexPath, let newIndexPath = newIndexPath else {return}
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.insertRows(at: [newIndexPath], with: .fade)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
        configure()
    }
    
}

protocol BookmarkControllerDelegate: class {
    func didTapBookmark(articleURL: URL)
}
