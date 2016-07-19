//
//  BookmarkTBVC.swift
//  Kiwix
//
//  Created by Chris on 1/10/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import CoreData
import DZNEmptyDataSet

class BookmarkTBVC: UITableViewController, NSFetchedResultsControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        clearsSelectionOnViewWillAppear = true
        title = LocalizedStrings.bookmarks
        tableView.estimatedRowHeight = 66.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.allowsMultipleSelectionDuringEditing = true
        
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        setEditing(false, animated: false)
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
        navigationController?.setToolbarHidden(!editing, animated: animated)
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
            if let articleImageData = article.thumbImageData {
                return UIImage(data: articleImageData)
            } else if let bookFavIconImageData = article.book?.favIcon {
                return UIImage(data: bookFavIconImageData)
            } else {
                return nil
            }
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
        guard let navigationController = navigationController?.presentingViewController as? UINavigationController else {return}
        guard let mainVC = navigationController.topViewController as? MainController else {return}
        guard let article = fetchedResultController.objectAtIndexPath(indexPath) as? Article else {return}
        mainVC.load(article.url)
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
                context.deleteObject(article)
            })
        }
        return [remove]
    }
    
    // MARK: - Fetched Result Controller Delegate
    
    let managedObjectContext = UIApplication.appDelegate.managedObjectContext
    
    lazy var fetchedResultController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Article")
        let dateDescriptor = NSSortDescriptor(key: "bookmarkDate", ascending: false)
        let titleDescriptor = NSSortDescriptor(key: "title", ascending: true)
        fetchRequest.sortDescriptors = [dateDescriptor, titleDescriptor]
        fetchRequest.predicate = NSPredicate(format: "isBookmarked == true")
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: "BookmarkFRC")
        fetchedResultsController.delegate = self
        fetchedResultsController.performFetch(deleteCache: false)
        return fetchedResultsController
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
            tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Fade)
        case .Delete:
            guard let indexPath = indexPath else {return}
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        case .Update:
            guard let indexPath = indexPath, let cell = tableView.cellForRowAtIndexPath(indexPath) else {return}
            configureCell(cell, atIndexPath: indexPath)
        case .Move:
            guard let indexPath = indexPath, let newIndexPath = newIndexPath else {return}
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Fade)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }

    // MARK: - Action
    
    @IBAction func editingButtonTapped(sender: UIBarButtonItem) {
        setEditing(!editing, animated: true)
    }
    
    @IBAction func removeBookmarkButtonTapped(sender: UIBarButtonItem) {
        guard editing else {return}
        guard let selectedIndexPathes = tableView.indexPathsForSelectedRows else {return}
        let artiicles = selectedIndexPathes.flatMap() {fetchedResultController.objectAtIndexPath($0) as? Article}
        let context = NSManagedObjectContext.mainQueueContext
        context.performBlock { 
            artiicles.forEach() {
                $0.isBookmarked = false
                $0.bookmarkDate = nil
            }
        }
    }
    
    @IBAction func dismissButtonTapped(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}

extension LocalizedStrings {
    class var bookmarks: String {return NSLocalizedString("Bookmarks", comment: "")}
    class var bookmarkAddGuide: String {return NSLocalizedString("To add a bookmark, long press the star button when reading an article", comment: "")}
}
