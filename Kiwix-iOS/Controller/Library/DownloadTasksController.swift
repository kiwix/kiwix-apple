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

class DownloadTasksController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

    @IBOutlet weak var tableView: UITableView!
    var timer: NSTimer?
    
    // MARK: - Override
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        tabBarItem.title = LocalizedStrings.LibraryTabTitle.download
        tabBarItem.image = UIImage(named: "Download")
        tabBarItem.selectedImage = UIImage(named: "DownloadFilled")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = 90.0
        tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
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
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultController.sections?.count ?? 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionInfo = fetchedResultController.sections?[section] else {return 0}
        return sectionInfo.numberOfObjects
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath, animated: Bool = false) {
        guard let downloadTask = fetchedResultController.objectAtIndexPath(indexPath) as? DownloadTask,
            let book = downloadTask.book,
            let cell = cell as? DownloadBookCell else {return}
        
        cell.titleLabel.text = book.title
        cell.favIcon.image = UIImage(data: book.favIcon ?? NSData())
        
        if let progress = Network.shared.operations[book.id]?.progress {
            cell.progressLabel.text = progress.fractionCompletedDescription
            cell.progressView.setProgress(Float(progress.fractionCompleted), animated: animated)
            cell.detailLabel.text = {
                let string = progress.progressAndSpeedDescription
                if downloadTask.state == .Downloading {
                    if string.containsString(" — ") {
                        return string.stringByReplacingOccurrencesOfString(" — ", withString: "\n")
                    } else {
                        return string + "\n" + "Estimating"
                    }
                } else {
                    return string + "\n" + String(downloadTask.state)
                }
            }()
        } else {
            let progress = Double(downloadTask.totalBytesWritten) / Double(book.fileSize)
            cell.progressLabel.text = DownloadTask.percentFormatter.stringFromNumber(NSNumber(double: progress))
            cell.progressView.setProgress(Float(progress), animated: animated)
            cell.detailLabel.text = {
                let downloadedSize = NSByteCountFormatter.stringFromByteCount(downloadTask.totalBytesWritten, countStyle: .File)
                let fileSize = book.fileSizeDescription
                return String(format: "%@ of %@ completed", downloadedSize, fileSize) + "\n" + String(downloadTask.state)
            }()
        }
        
    }
    
    // MARK: Other Data Source
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard tableView.numberOfSections > 1 else {return nil}
        guard let languageName = fetchedResultController.sections?[section].name else {return nil}
        return languageName
    }
    
    func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        let sectionIndexTitles = fetchedResultController.sectionIndexTitles
        guard sectionIndexTitles.count > 2 else {return nil}
        return sectionIndexTitles
    }
    
    func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
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
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {}
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        guard let downloadTask = self.fetchedResultController.objectAtIndexPath(indexPath) as? DownloadTask else {return nil}
        
        var actions = [UITableViewRowAction]()
        switch downloadTask.state {
        case .Downloading:
            let pause = UITableViewRowAction(style: .Normal, title: "Pause") { (action, indexPath) in
                downloadTask.state = .Paused
                
                guard let bookID = downloadTask.book?.id else {return}
                Network.shared.operations[bookID]?.cancel(produceResumeData: true)
                tableView.setEditing(false, animated: true)
            }
            actions.insert(pause, atIndex: 0)
        case .Paused:
            if let book = downloadTask.book,
                let resumeData = Preference.resumeData[book.id] {
                let resume = UITableViewRowAction(style: .Normal, title: "Resume") { (action, indexPath) in
                    let task = Network.shared.session.downloadTaskWithResumeData(resumeData)
                    let operation = DownloadBookOperation(downloadTask: task)
                    Network.shared.queue.addOperation(operation)
                    tableView.setEditing(false, animated: true)
                }
                actions.insert(resume, atIndex: 0)
            } else {
                let restart = UITableViewRowAction(style: .Normal, title: "Restart") { (action, indexPath) in
                    guard let bookID = downloadTask.book?.id,
                        let operation = DownloadBookOperation(bookID: bookID) else {return}
                    Network.shared.queue.addOperation(operation)
                    tableView.setEditing(false, animated: true)
                }
                actions.insert(restart, atIndex: 0)
            }
        default:
            break
        }
        
        let cancel = UITableViewRowAction(style: .Destructive, title: LocalizedStrings.Common.cancel) { (action, indexPath) -> Void in
            if let bookID = downloadTask.book?.id {
                if let operation = Network.shared.operations[bookID] {
                    // When download is ongoing
                    // Cancel the download operation
                    // URLSessionTaskDelegate will update coredata and do clean up
                    operation.cancel(produceResumeData: false)
                } else {
                    // When download is paused
                    // Remove resume data
                    // Delete downloadTask object and set book to not local
                    downloadTask.book?.removeResumeData()
                    downloadTask.book?.isLocal = NSNumber(bool: false)
                    self.managedObjectContext.deleteObject(downloadTask)
                }
            } else {
                // In case of something goes wrong, and cannot find the book related to a download task, allow user to delete the row
                self.managedObjectContext.deleteObject(downloadTask)
            }
            tableView.setEditing(false, animated: true)
        }
        actions.insert(cancel, atIndex: 0)
        
        return actions
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
