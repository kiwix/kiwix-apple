//
//  BookmarkController.swift
//  Kiwix
//
//  Created by Chris Li on 9/27/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import CoreData
import Operations
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
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        switch (editing, isTopViewController) {
        case (true, true), (true, false):
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Trash, target: self, action: #selector(BookmarkController.trashButtonTapped(_:)))
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(BookmarkController.editButtonTapped(_:)))
        case (false, true):
            navigationItem.leftBarButtonItem = UIBarButtonItem(imageNamed: "Cross", target: self, action: #selector(BookmarkController.dismissSelf))
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: #selector(BookmarkController.editButtonTapped(_:)))
        case (false, false):
            navigationItem.leftBarButtonItem = nil
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: #selector(BookmarkController.editButtonTapped(_:)))
        }
    }
    
    // MARK: - Action
    
    func trash(articles articles: [Article]) {
        let operation = BookmarkTrashOperation(articles: articles)
        operation.addObserver(DidFinishObserver { _ in
            NSOperationQueue.mainQueue().addOperationWithBlock({ 
                guard self.fetchedResultController.fetchedObjects?.count == 0 else {return}
                self.navigationController?.popViewControllerAnimated(true)
            })
        })
        GlobalQueue.shared.addOperation(operation)
    }
    
    func trashButtonTapped(sender: UIBarButtonItem) {
        guard editing else {return}
        guard let selectedIndexPathes = tableView.indexPathsForSelectedRows else {return}
        let articles = selectedIndexPathes.flatMap() {fetchedResultController.objectAtIndexPath($0) as? Article}
        trash(articles: articles)
    }
    
    @IBAction func editButtonTapped(sender: UIBarButtonItem) {
        setEditing(!editing, animated: true)
    }
    
    func dismissSelf() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - Empty table datasource & delegate
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "BookmarkColor")
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text = NSLocalizedString("Bookmarks", comment: "Bookmarks view title")
        let attributes = [NSFontAttributeName: UIFont.boldSystemFontOfSize(18.0),
                          NSForegroundColorAttributeName: UIColor.darkGrayColor()]
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text = NSLocalizedString("To add a bookmark, long press the star button when reading an article", comment: "Bookmarks view message")
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .ByWordWrapping
        style.alignment = .Center
        let attributes = [NSFontAttributeName: UIFont.boldSystemFontOfSize(14.0),
                          NSForegroundColorAttributeName: UIColor.lightGrayColor(),
                          NSParagraphStyleAttributeName: style]
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    func spaceHeightForEmptyDataSet(scrollView: UIScrollView!) -> CGFloat {
        return 30.0
    }

    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultController.sections?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionInfo = fetchedResultController.sections?[section] else {return 0}
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let article = fetchedResultController.objectAtIndexPath(indexPath) as? Article
        if let _ = article?.snippet {
            let cell = tableView.dequeueReusableCellWithIdentifier("BookmarkSnippetCell", forIndexPath: indexPath)
            configureSnippetCell(cell, atIndexPath: indexPath)
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("BookmarkCell", forIndexPath: indexPath)
            configureCell(cell, atIndexPath: indexPath)
            return cell
        }
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        guard let cell = cell as? BookmarkCell else {return}
        guard let article = fetchedResultController.objectAtIndexPath(indexPath) as? Article else {return}
        
        cell.thumbImageView.image = {
            guard let data = article.thumbImageData else {return nil}
            return UIImage(data: data)
        }()
        cell.titleLabel.text = article.title
        cell.subtitleLabel.text = article.book?.title
    }
    
    func configureSnippetCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        configureCell(cell, atIndexPath: indexPath)
        
        guard let cell = cell as? BookmarkSnippetCell else {return}
        guard let article = fetchedResultController.objectAtIndexPath(indexPath) as? Article else {return}
        cell.snippetLabel.text = article.snippet
    }
    
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard !tableView.editing else {return}
        defer {dismissViewControllerAnimated(true, completion: nil)}
        guard let article = fetchedResultController.objectAtIndexPath(indexPath) as? Article,
            let url = article.url else {return}
        
        let operation = ArticleLoadOperation(url: url)
        GlobalQueue.shared.add(load: operation)
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {}
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let remove = UITableViewRowAction(style: .Destructive, title: LocalizedStrings.remove) { (action, indexPath) -> Void in
            guard let article = self.fetchedResultController.objectAtIndexPath(indexPath) as? Article else {return}
            let context = NSManagedObjectContext.mainQueueContext
            context.performBlockAndWait({ () -> Void in
                article.isBookmarked = false
            })
            self.trash(articles: [article])
        }
        return [remove]
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.min
    }
    
    // MARK: - Fetched Result Controller Delegate
    
    let managedObjectContext = NSManagedObjectContext.mainQueueContext
    lazy var fetchedResultController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Article")
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
                                                    cacheName: self.book == nil ? nil : "BookmarksFRC" + NSBundle.appShortVersion)
        controller.delegate = self
        controller.performFetch(deleteCache: false)
        return controller
    }()
    
    // MARK: - Fetched Result Controller Delegate
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        default:
            return
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            guard let newIndexPath = newIndexPath else {return}
            tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Left)
        case .Delete:
            guard let indexPath = indexPath else {return}
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Right)
        case .Update:
            guard let indexPath = indexPath, let cell = tableView.cellForRowAtIndexPath(indexPath) else {return}
            configureCell(cell, atIndexPath: indexPath)
        case .Move:
            guard let indexPath = indexPath, let newIndexPath = newIndexPath else {return}
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Right)
            tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Left)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
}
