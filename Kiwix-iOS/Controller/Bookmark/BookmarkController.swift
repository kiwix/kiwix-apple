//
//  BookmarkController.swift
//  Kiwix
//
//  Created by Chris Li on 9/27/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import CoreData
import ProcedureKit
import DZNEmptyDataSet

class BookmarkController: UITableViewController, NSFetchedResultsControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    var book: Book?
    var isTopViewController: Bool {
        return self == navigationController?.viewControllers.first
    }
    
    // MARK: - Overrides

    override func viewDidLoad() {
        super.viewDidLoad()
        title = LocalizedStrings.bookmarks
        clearsSelectionOnViewWillAppear = true
        tableView.estimatedRowHeight = 66.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        
        if isTopViewController {
            navigationItem.leftBarButtonItem = UIBarButtonItem(imageNamed: "Cross", target: self, action: #selector(BookmarkController.dismissSelf))
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        switch (editing, isTopViewController) {
        case (true, true), (true, false):
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(BookmarkController.trashButtonTapped(_:)))
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(BookmarkController.editButtonTapped(_:)))
        case (false, true):
            navigationItem.leftBarButtonItem = UIBarButtonItem(imageNamed: "Cross", target: self, action: #selector(BookmarkController.dismissSelf))
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(BookmarkController.editButtonTapped(_:)))
        case (false, false):
            navigationItem.leftBarButtonItem = nil
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(BookmarkController.editButtonTapped(_:)))
        }
    }
    
    // MARK: - Action
    
    func trash(articles: [Article]) {
        let operation = BookmarkTrashOperation(articles: articles)
        operation.addObserver(DidFinishObserver { _ in
            OperationQueue.mainQueue().addOperationWithBlock({ 
                guard self.fetchedResultController.fetchedObjects?.count == 0 else {return}
                self.navigationController?.popViewControllerAnimated(true)
            })
        })
        GlobalQueue.shared.addOperation(operation)
    }
    
    func trashButtonTapped(_ sender: UIBarButtonItem) {
        guard isEditing else {return}
        guard let selectedIndexPathes = tableView.indexPathsForSelectedRows else {return}
        let articles = selectedIndexPathes.flatMap() {fetchedResultController.object(at: $0) as? Article}
        trash(articles: articles)
    }
    
    @IBAction func editButtonTapped(_ sender: UIBarButtonItem) {
        setEditing(!isEditing, animated: true)
    }
    
    func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Empty table datasource & delegate
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "BookmarkColor")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let text = LocalizedStrings.bookmarks
        let attributes = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 18.0),
                          NSForegroundColorAttributeName: UIColor.darkGray]
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let text = NSLocalizedString("To add a bookmark, long press the star button when reading an article", comment: "Bookmarks view message")
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byWordWrapping
        style.alignment = .center
        let attributes = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14.0),
                          NSForegroundColorAttributeName: UIColor.lightGray,
                          NSParagraphStyleAttributeName: style]
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    func spaceHeight(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return 30.0
    }

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultController.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionInfo = fetchedResultController.sections?[section] else {return 0}
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let article = fetchedResultController.object(at: indexPath) as? Article
        if let _ = article?.snippet {
            let cell = tableView.dequeueReusableCell(withIdentifier: "BookmarkSnippetCell", for: indexPath)
            configureSnippetCell(cell, atIndexPath: indexPath)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "BookmarkCell", for: indexPath)
            configureCell(cell, atIndexPath: indexPath)
            return cell
        }
    }
    
    func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        guard let cell = cell as? BookmarkCell else {return}
        guard let article = fetchedResultController.object(at: indexPath) as? Article else {return}
        
        cell.thumbImageView.image = {
            guard let data = article.thumbImageData else {return nil}
            return UIImage(data: data)
        }()
        cell.titleLabel.text = article.title
        cell.subtitleLabel.text = article.book?.title
    }
    
    func configureSnippetCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        configureCell(cell, atIndexPath: indexPath)
        
        guard let cell = cell as? BookmarkSnippetCell else {return}
        guard let article = fetchedResultController.object(at: indexPath) as? Article else {return}
        cell.snippetLabel.text = article.snippet
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !tableView.isEditing else {return}
        defer {dismiss(animated: true, completion: nil)}
        guard let article = fetchedResultController.object(at: indexPath) as? Article,
            let url = article.url else {return}
        
        let operation = ArticleLoadOperation(url: url)
        GlobalQueue.shared.add(load: operation)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {}
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let remove = UITableViewRowAction(style: UITableViewRowActionStyle(), title: LocalizedStrings.remove) { (action, indexPath) -> Void in
            guard let article = self.fetchedResultController.object(at: indexPath) as? Article else {return}
            let context = NSManagedObjectContext.mainQueueContext
            context.performAndWait({ () -> Void in
                article.isBookmarked = false
            })
            self.trash(articles: [article])
        }
        return [remove]
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    // MARK: - Fetched Result Controller Delegate
    
    let managedObjectContext = NSManagedObjectContext.mainQueueContext
    lazy var fetchedResultController: NSFetchedResultsController = { () -> <<error type>> in 
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Article")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "bookmarkDate", ascending: false),
                                        NSSortDescriptor(key: "title", ascending: true)]
        fetchRequest.predicate = {
            if let book = self.book {
                return NSPredicate(format: "book = %@ AND isBookmarked = true", book)
            } else {
                return NSPredicate(format: "isBookmarked = true")
            }
        }()
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                    managedObjectContext: self.managedObjectContext,
                                                    sectionNameKeyPath: nil,
                                                    cacheName: self.book == nil ? nil : "BookmarksFRC" + Bundle.appShortVersion)
        controller.delegate = self
        controller.performFetch(deleteCache: false)
        return controller
    }()
    
    // MARK: - Fetched Result Controller Delegate
    
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
            tableView.insertRows(at: [newIndexPath], with: .left)
        case .delete:
            guard let indexPath = indexPath else {return}
            tableView.deleteRows(at: [indexPath], with: .right)
        case .update:
            guard let indexPath = indexPath, let cell = tableView.cellForRow(at: indexPath) else {return}
            configureCell(cell, atIndexPath: indexPath)
        case .move:
            guard let indexPath = indexPath, let newIndexPath = newIndexPath else {return}
            tableView.deleteRows(at: [indexPath], with: .right)
            tableView.insertRows(at: [newIndexPath], with: .left)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
