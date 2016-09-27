//
//  BookmarkController.swift
//  Kiwix
//
//  Created by Chris Li on 9/27/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import CoreData

class BookmarkController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    var book: Book?
    
    // MARK: - Overrides

    override func viewDidLoad() {
        super.viewDidLoad()
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
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        cell.textLabel?.text = article?.title
        return cell
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
}
