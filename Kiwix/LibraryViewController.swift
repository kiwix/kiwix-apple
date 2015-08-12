//
//  LibraryViewController.swift
//  Kiwix
//
//  Created by Chris Li on 8/11/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit
import CoreData

class LibraryViewController: UITableViewController, NSFetchedResultsControllerDelegate, BookCellDelegate {

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    var indexPathsShouldDisplayDetailDic = ["Online":[NSIndexPath](), "Local":[NSIndexPath]()]
    var downloadProgressShouldRefresh = true
    var timer = NSTimer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        performFetch()
        adjustForiPad()
        configureTableView()
        
        NSUserDefaults.standardUserDefaults().addObserver(self, forKeyPath: "libraryFilteredLanguages", options: NSKeyValueObservingOptions.New, context: nil)
        timer = NSTimer.scheduledTimerWithTimeInterval(0.25, target: self, selector: "resetDownloadProgressShouldRefresh", userInfo: nil, repeats: true)
        LibraryRefresher.sharedInstance.refreshLibraryIfNecessary()
    }
    
    deinit {
        timer.invalidate()
        NSUserDefaults.standardUserDefaults().removeObserver(self, forKeyPath: "libraryFilteredLanguages")
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "libraryFilteredLanguages" {
            NSFetchedResultsController.deleteCacheWithName("OnlineFetchedResultsController")
            self.onlineFetchedResultController.fetchRequest.predicate = onlineCompoundPredicate()
            self.indexPathsShouldDisplayDetailDic["Online"]?.removeAll()
            performFetch()
            tableView.reloadData()
        }
    }
    
    func resetDownloadProgressShouldRefresh() {
        downloadProgressShouldRefresh = true
    }
    
    // MARK: - Initializations and view setup
    
    func configureTableView() {
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = tableFooterView()
        tableView.backgroundColor = UIColor.groupTableViewBackgroundColor()
    }
    
    func adjustForiPad() {
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            self.preferredContentSize = CGSizeMake(400, 500)
            self.edgesForExtendedLayout = .None
        }
    }
    
    // MARK: - BookCellDelegate
    
    func didTapOnAccessoryViewForCell(atIndexPath indexPath: NSIndexPath?) {
        if segmentedControl.selectedSegmentIndex == 1 {
        } else {
            let cell = tableView.cellForRowAtIndexPath(indexPath!) as! BookOrdinaryCell
            let book = selectedFetchedResultController.objectAtIndexPath(indexPath!) as! Book
            
            switch cell.downloadState {
            case BookDownloadState.GoAhead:
                Downloader.sharedInstance.startDownloadBook(book)
            case BookDownloadState.WithCaution:
                let actionProceed = UIAlertAction(title: "Proceed", style: .Default, handler: { (action) -> Void in
                    Downloader.sharedInstance.startDownloadBook(book)
                })
                let actionCancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
                let alert = Utilities.alertWith("Space alert.", message: "This book will take up more than 80% of your free space.", actions: [actionProceed, actionCancel])
                self.navigationController?.presentViewController(alert, animated: true, completion: nil)
            case BookDownloadState.NotAllowed:
                let actionCancel = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
                let alert = Utilities.alertWith("Not enough space.", message: "Please free up some space and try again.", actions: [actionCancel])
                self.navigationController?.presentViewController(alert, animated: true, completion: nil)
            case BookDownloadState.Finished:
                let actionProceed = UIAlertAction(title: "Yes", style: .Default, handler: { (action) -> Void in
                    if Utilities.removeBookFromDisk(book) == true {
                        book.managedObjectContext?.deleteObject(book)
                    }
                })
                let actionCancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
                let alert = Utilities.alertWith("Delete the book?", message: "This is not recoverable.", actions: [actionProceed, actionCancel])
                self.navigationController?.presentViewController(alert, animated: true, completion: nil)
            default:
                return
            }
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.selectedFetchedResultController.sections?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.selectedFetchedResultController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView.numberOfSections > 1 {
            return self.selectedFetchedResultController.sections?[section].name
        } else {
            return nil
        }
    }
    
    override func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        let sectionIndexTitles = self.selectedFetchedResultController.sectionIndexTitles
        if sectionIndexTitles.count > 1 && segmentedControl.selectedSegmentIndex == 0 {
            return sectionIndexTitles
        } else {
            return nil
        }
    }
    
    override func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        return self.selectedFetchedResultController.sectionForSectionIndexTitle(title, atIndex: index)
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if segmentedControl.selectedSegmentIndex == 1 {
            return true
        } else {
            return false
        }
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if segmentedControl.selectedSegmentIndex == 0 || segmentedControl.selectedSegmentIndex == 2 {
            let cell = tableView.dequeueReusableCellWithIdentifier("BookOrdinaryCell", forIndexPath: indexPath)
            self.configureCell(cell, atIndexPath: indexPath, animated: false)
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("BookDownloadingCell", forIndexPath: indexPath)
            self.configureCell(cell, atIndexPath: indexPath, animated: false)
            return cell
        }
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath, animated: Bool) {
        if let book = selectedFetchedResultController.objectAtIndexPath(indexPath) as? Book {
            if cell.isKindOfClass(BookOrdinaryCell) {
                let cell = cell as! BookOrdinaryCell
                cell.titleLabel.text = book.title ?? ""
                cell.subtitleLabel.text = subtitleStringOfBook(book, atIndexPath: indexPath)
                cell.hasPicIndicator.backgroundColor = book.isNoPic!.boolValue ? UIColor.lightGrayColor() : Utilities.customTintColor()
                cell.favIcon.image = book.favIcon != nil ? UIImage(data: book.favIcon!) : nil
                cell.indexPath = indexPath
                cell.downloadState = downloadStateOfBook(book)
                cell.delegate = self
            } else if cell.isKindOfClass(BookDownloadingCell) {
                let cell = cell as! BookDownloadingCell
                cell.titleLabel.text = book.title ?? ""
                cell.dateLabel.text = Book.formattedDateStringOf(book)
                cell.articleLabel.text = Book.formattedArticleCountOf(book)
                cell.hasPicIndicator.backgroundColor = book.isNoPic!.boolValue ? UIColor.lightGrayColor() : Utilities.customTintColor()
                cell.favIcon.image = book.favIcon != nil ? UIImage(data: book.favIcon!) : nil
                cell.downloadState = downloadStateOfBook(book)
                cell.indexPath = indexPath
                cell.delegate = self
                if let totalBytesWritten = Downloader.sharedInstance.totalBytesWrittenDic[book.idString!], fileSize = book.fileSize?.longLongValue {
                    if !animated || downloadProgressShouldRefresh {
                        cell.progressView.setProgress(Float(totalBytesWritten)/Float(fileSize * 1024), animated: false)
                        cell.fileSizeLabel.text = Utilities.formattedFileSizeStringFromByteCount(totalBytesWritten) + " of " + Utilities.formattedFileSizeStringFromByteCount(fileSize * 1024)
                    }
                    if animated {downloadProgressShouldRefresh = false}
                } else {
                    cell.progressView.setProgress(0.0, animated: false)
                    cell.fileSizeLabel.text = "Unknown"
                }
                cell.progressLabel.text = String(format: "%.0f%%", cell.progressView.progress*100)
            }
        } else {
            print("Cannot find book obj in selectedFetchedResultController")
        }
    }
    
    //MARK: Table View Delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if segmentedControl.selectedSegmentIndex == 0 || segmentedControl.selectedSegmentIndex == 2{
            if let index = indexPathsShouldDisplayDetailDic["Online"]!.indexOf(indexPath) {
                indexPathsShouldDisplayDetailDic["Online"]!.removeAtIndex(index)
            } else {
                indexPathsShouldDisplayDetailDic["Online"]!.append(indexPath)
            }
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if (segmentedControl.selectedSegmentIndex == 0 ||  segmentedControl.selectedSegmentIndex == 2) && tableView.numberOfSections > 1{
            return 20.0
        } else {
            return 0.0
        }
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if segmentedControl.selectedSegmentIndex == 0 ||  segmentedControl.selectedSegmentIndex == 2 {
            let header:UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
            header.textLabel!.font = UIFont.boldSystemFontOfSize(14)
        }
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let cancelAction = UITableViewRowAction(style: .Destructive, title: "Cancel") { (action, indexPath) -> Void in
            let book = self.selectedFetchedResultController.objectAtIndexPath(indexPath) as! Book
            Downloader.sharedInstance.cancelDownloadBook(book)
        }
        return [cancelAction]
    }
    
    // MARK: Helper
    
    func tableFooterView() -> UIView {
        let count = self.selectedFetchedResultController.fetchedObjects!.count
        let availableSpaceFormatted = Utilities.formattedFileSizeStringFromByteCount(Utilities.availableDiskspaceInBytes())
        let preferredWidth = UIDevice.currentDevice().userInterfaceIdiom == .Pad ? preferredContentSize.width : tableView.frame.size.width
        if segmentedControl.selectedSegmentIndex == 0 {
            switch count {
            case 0:
                return Utilities.tableHeaderFooterView(withMessage: "No book available for download\n\(availableSpaceFormatted) available", andPreferredWidth: preferredWidth)
            case 1:
                return Utilities.tableHeaderFooterView(withMessage: "1 book available for download\n\(availableSpaceFormatted) available", andPreferredWidth: preferredWidth)
            default:
                return Utilities.tableHeaderFooterView(withMessage: "\(count) books available for download\n\(availableSpaceFormatted) available", andPreferredWidth: preferredWidth)
            }
        } else if segmentedControl.selectedSegmentIndex == 1 {
            switch count {
            case 0:
                return Utilities.tableHeaderFooterView(withMessage: "No book is downloading", andPreferredWidth: preferredWidth)
            case 1:
                return Utilities.tableHeaderFooterView(withMessage: "1 book is downloading", andPreferredWidth: preferredWidth)
            default:
                return Utilities.tableHeaderFooterView(withMessage: "\(count) books are downloading", andPreferredWidth: preferredWidth)
            }
        } else {
            switch count {
            case 0:
                return Utilities.tableHeaderFooterView(withMessage: "No book is on device", andPreferredWidth: preferredWidth)
            case 1:
                return Utilities.tableHeaderFooterView(withMessage: "1 book on device", andPreferredWidth: preferredWidth)
            default:
                return Utilities.tableHeaderFooterView(withMessage: "\(count) books are on device", andPreferredWidth: preferredWidth)
            }
        }
    }
    
    func downloadStateOfBook(book: Book) -> BookDownloadState {
        let bookSizeInBytes = book.fileSize!.longLongValue * 1024
        let freeSpaceInBytes = Utilities.availableDiskspaceInBytes()
        if segmentedControl.selectedSegmentIndex == 1 {
            if book.hasResumeData == nil {
                return .CanPause
            } else {
                return .CanResume
            }
        } else {
            if book.isLocal == true {
                return .Finished
            } else {
                if Int64(0.8 * Double(freeSpaceInBytes)) > bookSizeInBytes {
                    return .GoAhead
                } else if freeSpaceInBytes < bookSizeInBytes{
                    return .NotAllowed
                } else {
                    return .WithCaution
                }
            }
        }
    }
    
    func subtitleStringOfBook(book: Book, atIndexPath indexPath: NSIndexPath) -> String {
        var subtitleString: String = {
            let fileDateFormatted = Book.formattedDateStringOf(book)
            let fileSizeFormatted = book.fileSize != nil ? Utilities.formattedFileSizeStringFromByteCount(book.fileSize!.longLongValue * 1024) : ""
            // TODO: - Add articleCount = 1 case
            let articleCountFormatted = Book.formattedArticleCountOf(book)
            return fileDateFormatted + ", " + fileSizeFormatted + ", " + articleCountFormatted
            }()
        
        if self.indexPathsShouldDisplayDetailDic["Online"]!.contains(indexPath) {
            if let desc = book.desc {
                subtitleString = subtitleString + "\n" + desc
            }
            
            if let creator = book.creator, publisher = book.publisher {
                if creator == publisher {
                    subtitleString = subtitleString + "\n" + "Creator and publisher: " + creator
                } else {
                    subtitleString = subtitleString + "\n" + "Creator: " + creator + " Publisher: " + publisher
                }
            } else if let creator = book.creator {
                subtitleString = subtitleString + "\n" + "Creator: " + creator
            } else if let publisher = book.publisher {
                subtitleString = subtitleString + "\n" + "Publisher: " + publisher
            }
        }
        return subtitleString
    }
    
    // MARK: - Fetched Result Controller Initialization
    
    var selectedFetchedResultController: NSFetchedResultsController {
        get {
            switch segmentedControl.selectedSegmentIndex {
            case 0: return onlineFetchedResultController
            case 1: return downloadFetchedResultController
            default: return localFetchedResultController
            }
        }
    }
    
    lazy var downloadFetchedResultController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Book")
        //fetchRequest.fetchBatchSize = 20
        let langDescriptor = NSSortDescriptor(key: "language", ascending: true)
        let titleDescriptor = NSSortDescriptor(key: "title", ascending: true)
        fetchRequest.sortDescriptors = [langDescriptor, titleDescriptor]
        fetchRequest.predicate = NSPredicate(format: "isLocal == NO AND totalBytesWritten != nil", argumentArray: nil)
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "language", cacheName: "DownloadFetchedResultsController")
        fetchedResultsController.delegate = self
        return fetchedResultsController
        }()
    
    lazy var localFetchedResultController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Book")
        //fetchRequest.fetchBatchSize = 20
        let langDescriptor = NSSortDescriptor(key: "language", ascending: true)
        let titleDescriptor = NSSortDescriptor(key: "title", ascending: true)
        fetchRequest.sortDescriptors = [langDescriptor, titleDescriptor]
        fetchRequest.predicate = NSPredicate(format: "isLocal == YES", argumentArray: nil)
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "language", cacheName: "LocalFetchedResultsController")
        fetchedResultsController.delegate = self
        return fetchedResultsController
        }()
    
    lazy var onlineFetchedResultController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Book")
        //fetchRequest.fetchBatchSize = 20
        let langDescriptor = NSSortDescriptor(key: "language", ascending: true)
        let titleDescriptor = NSSortDescriptor(key: "title", ascending: true)
        fetchRequest.sortDescriptors = [langDescriptor, titleDescriptor]
        fetchRequest.predicate = self.onlineCompoundPredicate()
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "language", cacheName: "OnlineFetchedResultsController")
        fetchedResultsController.delegate = self
        return fetchedResultsController
        }()
    
    func onlineCompoundPredicate() -> NSPredicate {
        let langCompoundPredicate: NSCompoundPredicate? = {
            if let filteredLangNames = Preference.libraryFilteredLanguages {
                if filteredLangNames.count > 0 {
                    var langPredicates = [NSPredicate]()
                    for langName in filteredLangNames {
                        langPredicates.append(NSPredicate(format: "language = %@", langName))
                    }
                    return NSCompoundPredicate(orPredicateWithSubpredicates: langPredicates)
                }
            }
            return nil
            }()
        
        let isNotLocalPredicate = NSPredicate(format: "isLocal == NO AND totalBytesWritten == nil", argumentArray: nil)
        
        if langCompoundPredicate != nil {
            return NSCompoundPredicate(andPredicateWithSubpredicates: [langCompoundPredicate!, isNotLocalPredicate])
        } else {
            return isNotLocalPredicate
        }
    }
    
    func performFetch() {
//        NSFetchedResultsController.deleteCacheWithName("DownloadFetchedResultsController")
//        NSFetchedResultsController.deleteCacheWithName("LocalFetchedResultsController")
//        NSFetchedResultsController.deleteCacheWithName("OnlineFetchedResultsController")
        do {
            try self.onlineFetchedResultController.performFetch()
            try self.downloadFetchedResultController.performFetch()
            try self.localFetchedResultController.performFetch()
        } catch let error as NSError {
            print("fetchedResultController performFetch failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: Fetched Result Controller Delegate
    
    func shouldRespondeToModelChange(controller:NSFetchedResultsController) -> Bool {
        let isPresentingOnlineSegment = controller === selectedFetchedResultController && segmentedControl.selectedSegmentIndex == 0
        let isPresentingDownloadSegment = controller === selectedFetchedResultController && segmentedControl.selectedSegmentIndex == 1
        let isPresentingLocalSegment = controller === selectedFetchedResultController && segmentedControl.selectedSegmentIndex == 2
        return isPresentingOnlineSegment || isPresentingDownloadSegment || isPresentingLocalSegment
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        if shouldRespondeToModelChange(controller) {
            self.tableView.beginUpdates()
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        if shouldRespondeToModelChange(controller) {
            switch type {
            case .Insert:
                self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
            case .Delete:
                self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
            default:
                return
            }
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        // suspected bug
        if type.rawValue == 0 {
            return
        }
        
        if shouldRespondeToModelChange(controller) {
            switch type {
            case .Insert:
                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            case .Delete:
                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            case .Update:
                self.configureCell(tableView.cellForRowAtIndexPath(indexPath!)!, atIndexPath: indexPath!, animated: true)
            case .Move:
                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            }
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        if shouldRespondeToModelChange(controller) {
            tableView.tableFooterView = tableFooterView()
            self.tableView.endUpdates()
        }
    }
    
    // MARK: - Actions
    
    @IBAction func refresh(sender: UIBarButtonItem) {
        LibraryRefresher.sharedInstance.fetchBookData()
    }
    
    @IBAction func segmentedControlChanged(sender: UISegmentedControl) {
        tableView.reloadData()
        tableView.tableFooterView = tableFooterView()
    }
}
