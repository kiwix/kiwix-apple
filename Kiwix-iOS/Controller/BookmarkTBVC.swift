//
//  BookmarkTBVC.swift
//  Kiwix
//
//  Created by Chris on 1/10/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import CoreData

class BookmarkTBVC: UITableViewController, NSFetchedResultsControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        clearsSelectionOnViewWillAppear = true
        title = LocalizedStrings.bookmarks
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let numberOfArticles = fetchedResultController.fetchedObjects?.count ?? 0
        tableView.setBackgroundText(numberOfArticles == 0 ? LocalizedStrings.bookmarkAddGuide : nil)
        isOnScreen = true
        tableView.reloadData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        isOnScreen = false
    }
    
    var isOnScreen = false
    let managedObjectContext = UIApplication.appDelegate.managedObjectContext
    
    lazy var fetchedResultController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Article")
        let dateDescriptor = NSSortDescriptor(key: "lastReadDate", ascending: false)
        let titleDescriptor = NSSortDescriptor(key: "title", ascending: true)
        fetchRequest.sortDescriptors = [dateDescriptor, titleDescriptor]
        fetchRequest.predicate = NSPredicate(format: "isBookmarked == true")
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: "BookmarkFRC")
        fetchedResultsController.delegate = self
        fetchedResultsController.performFetch(deleteCache: false)
        return fetchedResultsController
    }()

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultController.sections?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionInfo = fetchedResultController.sections?[section] else {return 0}
        return sectionInfo.numberOfObjects
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ArticleCell", forIndexPath: indexPath)
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        guard let cell = cell as? ArticleCell else {return}
        guard let article = fetchedResultController.objectAtIndexPath(indexPath) as? Article else {return}
        guard let book = article.book else {return}
        
        cell.titleLabel.text = article.title
        cell.hasPicIndicator.backgroundColor = book.hasPic ? UIColor.havePicTintColor : UIColor.lightGrayColor()
        cell.favIcon.image = book.favIcon != nil ? UIImage(data: book.favIcon!) : nil
    }
    
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.min
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        defer {dismissViewControllerAnimated(true, completion: nil)}
        guard let navigationController = navigationController?.presentingViewController as? UINavigationController else {return}
        guard let mainVC = navigationController.topViewController as? MainVC else {return}
        guard let article = fetchedResultController.objectAtIndexPath(indexPath) as? Article else {return}
        mainVC.load(article.url)
    }

    // MARK: - Fetched Result Controller Delegate
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
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
        tableView.endUpdates()
    }

    // MARK: - Action
    
    @IBAction func dismissButtonTapped(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}

extension LocalizedStrings {
    class var bookmarks: String {return NSLocalizedString("Bookmarks", comment: "")}
    class var bookmarkAddGuide: String {return NSLocalizedString("To add a bookmark, long press the star button when reading an article", comment: "")}
}
