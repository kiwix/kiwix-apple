//
//  DownloadController.swift
//  Kiwix
//
//  Created by Chris Li on 8/24/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import CoreData
import DZNEmptyDataSet

class DownloadTasksController: UITableViewController, NSFetchedResultsControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

    var timer: NSTimer?
    
    // MARK: - Override
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        title = ""
        tabBarItem.title = LocalizedStrings.LibraryTabTitle.download
        tabBarItem.image = UIImage(named: "Download")
        tabBarItem.selectedImage = UIImage(named: "DownloadFilled")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.navigationItem.rightBarButtonItem = nil
        timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(DownloadTasksController.refreshProgress), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
        timer = nil
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else {return}
        switch identifier {
        case "ShowBookDetail":
            guard let navController = segue.destinationViewController as? UINavigationController,
                let bookDetailController = navController.topViewController as? BookDetailController,
                let cell = sender as? UITableViewCell,
                let indexPath = tableView.indexPathForCell(cell),
                let downloadTask = fetchedResultController.objectAtIndexPath(indexPath) as? DownloadTask,
                let book = downloadTask.book else {return}
            bookDetailController.book = book
        default:
            break
        }
    }
    
    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        let tabbarHeight = tabBarController?.tabBar.frame.height ?? 50
        let inset = UIEdgeInsetsMake(tableView.contentInset.top, 0, tabbarHeight, 0)
        tableView.contentInset = inset
        tableView.scrollIndicatorInsets = inset
    }
    
    // MARK: - Methods
    
    func refreshProgress() {
        tableView.visibleCells.forEach { (cell) in
            guard let indexPath = tableView.indexPathForCell(cell) else {return}
            configureCell(cell, atIndexPath: indexPath, animated: true)
        }
    }
    
    func refreshTabBarBadgeCount() {
        guard let count = fetchedResultController.fetchedObjects?.count else {return}
        tabBarItem.badgeValue = count > 0 ? "\(count)" : nil
    }
    
    // MARK: - TableView Data Source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultController.sections?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionInfo = fetchedResultController.sections?[section] else {return 0}
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath, animated: Bool = false) {
        guard let downloadTask = fetchedResultController.objectAtIndexPath(indexPath) as? DownloadTask,
            let book = downloadTask.book, let id = book.id,
            let cell = cell as? DownloadBookCell else {return}
        
        cell.titleLabel.text = book.title
        cell.favIcon.image = UIImage(data: book.favIcon ?? NSData())
        
        guard let progress = Network.shared.operations[id]?.progress else {return}
        cell.progressLabel.text = progress.fractionCompletedDescription
        cell.progressView.setProgress(Float(progress.fractionCompleted), animated: animated)
        cell.detailLabel.text = {
            let string = progress.progressAndSpeedDescription
            if string.containsString(" — ") {
                return string.stringByReplacingOccurrencesOfString(" — ", withString: "\n")
            } else {
                return string + "\n" + NSLocalizedString("Estimating Speed and Remaining Time", comment: "")
            }
        }()
    }
    
    // MARK: Other Data Source
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard tableView.numberOfSections > 1 else {return nil}
        guard let languageName = fetchedResultController.sections?[section].name else {return nil}
        return languageName
    }
    
    override func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        let sectionIndexTitles = fetchedResultController.sectionIndexTitles
        guard sectionIndexTitles.count > 2 else {return nil}
        return sectionIndexTitles
    }
    
    override func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        return fetchedResultController.sectionForSectionIndexTitle(title, atIndex: index)
    }
    
    // MARK: - Table View Delegate
    
//    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        guard tableView.numberOfSections > 1 else {return 0.0}
//        guard let headerText = self.tableView(tableView, titleForHeaderInSection: section) else {return 0.0}
//        guard headerText != "" else {return 0.0}
//        return 20.0
//    }
//    
//    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
//        guard let header = view as? UITableViewHeaderFooterView else {return}
//        header.textLabel?.font = UIFont.boldSystemFontOfSize(14)
//    }
//    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {}
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let pause = UITableViewRowAction(style: .Normal, title: "Pause") { (action, indexPath) in
            guard let downloadTask = self.fetchedResultController.objectAtIndexPath(indexPath) as? DownloadTask else {return}
            self.managedObjectContext.performBlock({
                downloadTask.state = .Paused
            })
            guard let bookID = downloadTask.book?.id else {return}
            Network.shared.operations[bookID]?.cancel(produceResumeData: true)
        }
        let cancel = UITableViewRowAction(style: .Destructive, title: LocalizedStrings.Common.cancel) { (action, indexPath) -> Void in
            guard let downloadTask = self.fetchedResultController.objectAtIndexPath(indexPath) as? DownloadTask else {return}
            if let bookID = downloadTask.book?.id {
                // Cancel the download operation, did cancel observer will do the rest
                Network.shared.operations[bookID]?.cancel(produceResumeData: false)
            } else {
                // In case of something goes wrong, and cannot find the book related to a download task, allow user to delete the row
                self.managedObjectContext.performBlock({
                    self.managedObjectContext.deleteObject(downloadTask)
                })
            }
        }
        return [cancel, pause]
    }
    
    // MARK: - Fetched Results Controller
    
    let managedObjectContext = UIApplication.appDelegate.managedObjectContext
    lazy var fetchedResultController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "DownloadTask")
        let creationTimeDescriptor = NSSortDescriptor(key: "creationTime", ascending: true)
        fetchRequest.sortDescriptors = [creationTimeDescriptor]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: "DownloadFRC" + NSBundle.buildVersion)
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
        refreshTabBarBadgeCount()
    }
    
}
