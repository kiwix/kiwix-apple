//
//  BookmarkTBVC.swift
//  Kiwix
//
//  Created by Chris Li on 8/18/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit
import CoreData

class BookmarkTBVC: UITableViewController, NSFetchedResultsControllerDelegate {

    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Bookmark"
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            self.navigationItem.leftBarButtonItem = nil
        }
        
        performFetch()
    }
    
    func performFetch() {
        //NSFetchedResultsController.deleteCacheWithName("BookmarkFetchedResultsController")
        do {
            try self.bookmarkFetchedResultController.performFetch()
        } catch let error as NSError {
            print("fetchedResultController performFetch failed: \(error.localizedDescription)")
        }
    }

    lazy var bookmarkFetchedResultController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Article")
        fetchRequest.fetchBatchSize = 20
        fetchRequest.predicate = NSPredicate(format: "isBookmarked = YES AND belongsToBook.downloadState == 3", argumentArray: nil)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lastReadDate", ascending: true)]
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: "BookmarkFetchedResultsController")
        fetchedResultsController.delegate = self
        return fetchedResultsController
        }()

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.bookmarkFetchedResultController.sections?.count ?? 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sectionInfo = self.bookmarkFetchedResultController.sections?[section] {
            return sectionInfo.numberOfObjects
        } else {
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ArticleCell", forIndexPath: indexPath) as! ArticleCell
        
        configureCell(cell, atIndexPath: indexPath)

        return cell
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath)  {
        if let cell = cell as? ArticleCell {
            if let article = bookmarkFetchedResultController.objectAtIndexPath(indexPath) as? Article  {
                cell.titleLabel?.text = article.title
                if let book = article.belongsToBook {
                    cell.favIcon.image = book.favIcon != nil ? UIImage(data: book.favIcon!) : nil
                    cell.hasPicIndicator.backgroundColor = book.isNoPic!.boolValue ? UIColor.lightGrayColor() : Utilities.customTintColor()
                }
            }
        }
    }
    
    // MARK: - Table view delegate 
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let navigationController = self.presentingViewController as? UINavigationController, let mainViewController = navigationController.topViewController as? MainViewController {
            if let article = bookmarkFetchedResultController.objectAtIndexPath(indexPath) as? Article {
                if let contentURLString = article.urlString, let idString = article.belongsToBook?.idString {
                    mainViewController.load(articleContentURLString: contentURLString, inBookWithID: idString)
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
            }
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    // MARK: - Fetched Result Controller
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Delete:
            self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        default:
            return
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        // suspected bug
        if type.rawValue == 0 {
            return
        }
        
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Update:
            self.configureCell(tableView.cellForRowAtIndexPath(indexPath!)!, atIndexPath: indexPath!)
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }
    
    // MARK: - Actions

    @IBAction func dismissSelf(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
