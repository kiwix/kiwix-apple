//
//  LibraryViewController.swift
//  Kiwix
//
//  Created by Chris Li on 8/11/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit
import CoreData

class LibraryViewController: UITableViewController, NSFetchedResultsControllerDelegate, BookCellDelegate, DownloaderDelegate, LibraryRefresherDelegate {

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    var indexPathsShouldDisplayDetailDic = ["Online":[NSIndexPath](), "Local":[NSIndexPath]()]
    var shouldRefreshDownloadProgress = true
    var oneSecondTimer = NSTimer()
    var oneMinuteTimer = NSTimer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        performFetch()
        adjustForDevice()
        configureTableView()
        configureToolBar()
        showPreferredLanguagePromptIfNeeded()
        Downloader.sharedInstance.delegate = self
        LibraryRefresher.sharedInstance.delegate = self
        
        NSUserDefaults.standardUserDefaults().addObserver(self, forKeyPath: "libraryFilteredLanguages", options: NSKeyValueObservingOptions.New, context: nil)
        oneSecondTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "resetDownloadProgressShouldRefresh", userInfo: nil, repeats: true)
        oneMinuteTimer = NSTimer.scheduledTimerWithTimeInterval(60.0, target: self, selector: "refreshMessageLabel", userInfo: nil, repeats: true)
    }
    
    deinit {
        oneSecondTimer.invalidate()
        oneMinuteTimer.invalidate()
        NSUserDefaults.standardUserDefaults().removeObserver(self, forKeyPath: "libraryFilteredLanguages")
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "libraryFilteredLanguages" {
            NSFetchedResultsController.deleteCacheWithName("OnlineFetchedResultsController")
            self.onlineFetchedResultController.fetchRequest.predicate = onlineCompoundPredicate()
            self.indexPathsShouldDisplayDetailDic["Online"]?.removeAll()
            performFetch()
            refreshTableView()
        }
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        tableView.tableFooterView = tableFooterView()
    }
    
    func refreshTableView() {
        tableView.reloadData()
        tableView.tableFooterView = tableFooterView()
    }
    
    func resetDownloadProgressShouldRefresh() {
        shouldRefreshDownloadProgress = true
    }
    
    func refreshMessageLabel() {
        messageBarButtonItem?.label.text = messageLabelText()
    }
    
    // MARK: - Initializations and view setup
    
    var messageBarButtonItem: MessageBarButtonItem?
    
    func configureTableView() {
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = tableFooterView()
        tableView.backgroundColor = UIColor.groupTableViewBackgroundColor()
        
    }
    
    func configureToolBar() {
        messageBarButtonItem = MessageBarButtonItem(withLabelText: messageLabelText())
        self.toolbarItems![2] = messageBarButtonItem!
    }
    
    func showPreferredLanguagePromptIfNeeded() {
        if !Preference.libraryHasShownPreferredLanguagePrompt {
            let preferredLanguages = Utilities.preferredLanguage()
            let message = Utilities.preferredLanguagePromptMessage(preferredLanguages)
            let applyFilterAction = UIAlertAction(title: "Yes", style: .Default, handler: { (action) -> Void in
                Preference.libraryFilteredLanguages = preferredLanguages
                self.performFetch()
            })
            let cancelAction = UIAlertAction(title: "No", style: .Cancel, handler: nil)
            let alert = Utilities.alertWith("Only Show Preferred Language?", message: message, actions: [applyFilterAction, cancelAction])
            self.navigationController?.presentViewController(alert, animated: true, completion: { () -> Void in
                Preference.libraryHasShownPreferredLanguagePrompt = true
            })
        }
    }
    
    func messageLabelText() -> String {
        if LibraryRefresher.sharedInstance.isRetrieving {return "Retrieving..."}
        if LibraryRefresher.sharedInstance.isProcessing {return "Processing..."}
        
        if let libraryLastRefreshTime = Preference.libraryLastRefreshTime {
            let interval = libraryLastRefreshTime.timeIntervalSinceNow * -1.0
            if interval < 60.0 {return "Last Refresh: just now"}
            
            let formatter = NSDateComponentsFormatter()
            formatter.allowedUnits = [.Year, .Month, .WeekOfMonth, .Day, .Hour, .Minute]
            formatter.unitsStyle = NSDateComponentsFormatterUnitsStyle.Short
            if let formattedInterval = formatter.stringFromTimeInterval(interval) {
                return "Last Refresh: " + formattedInterval + " ago"
            } else {
                return "Unknown"
            }
        } else {
            return "Never refreshed"
        }
    }
    
    func adjustForDevice() {
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            self.preferredContentSize = CGSizeMake(400, 500)
            self.edgesForExtendedLayout = .None
            self.navigationItem.leftBarButtonItem = nil
            self.navigationItem.rightBarButtonItem = nil
        } else {
            self.preferredContentSize = tableView.frame.size
        }
    }
    
    // MARK: - BookCellDelegate
    
    func didTapOnAccessoryViewForCell(atIndexPath indexPath: NSIndexPath?) {
        if segmentedControl.selectedSegmentIndex == 1 {
            if let cell = tableView.cellForRowAtIndexPath(indexPath!) as? BookDownloadingCell, book = selectedFetchedResultController.objectAtIndexPath(indexPath!) as? Book {
                switch cell.downloadState {
                case BookDownloadState.CanPause:
                    Downloader.sharedInstance.pauseDownloadBook(book)
                case BookDownloadState.CanResume:
                    Downloader.sharedInstance.resumeDownloadBook(book)
                default:
                    return
                }
            }
        } else {
            if let cell = tableView.cellForRowAtIndexPath(indexPath!) as? BookOrdinaryCell, book = selectedFetchedResultController.objectAtIndexPath(indexPath!) as? Book {
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
                            book.downloadState = 0
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
    }
    
    // MARK: DownloaderDelegate
    
    func bookDownloadProgressUpdate(book: Book, totalBytesWritten: Int64) {
        if segmentedControl.selectedSegmentIndex == 1 && shouldRefreshDownloadProgress {
            if let indexPath = self.downloadFetchedResultController.indexPathForObject(book), visibleIndexPaths = tableView.indexPathsForVisibleRows {
                if visibleIndexPaths.contains(indexPath) {
                    if let cell = tableView.cellForRowAtIndexPath(indexPath) as? BookDownloadingCell, fileSize = book.fileSize?.longLongValue {
                        cell.progressView.progress = Float(totalBytesWritten)/Float(fileSize * 1024)
                        cell.fileSizeLabel.text = Utilities.formattedFileSizeStringFromByteCount(totalBytesWritten) + " of " + Utilities.formattedFileSizeStringFromByteCount(fileSize * 1024)
                        cell.progressLabel.text = String(format: "%.0f%%", cell.progressView.progress*100)
                        self.shouldRefreshDownloadProgress = false
                    }
                }
            }
        }
    }
    
    // MARK: LibraryRefresherDelegate
    
    func startedRetrievingLibrary() {
        messageBarButtonItem?.label.text = "Retrieving..."
    }
    
    func startedProcessingLibrary() {
        messageBarButtonItem?.label.text = "Processing..."
    }
    
    func finishedProcessingLibrary() {
        messageBarButtonItem?.label.text = messageLabelText()
        showPreferredLanguagePromptIfNeeded()
    }
    
    func failedWithErrorMessage(message: String) {
        messageBarButtonItem?.label.text = message
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.selectedFetchedResultController.sections?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sectionInfo = self.selectedFetchedResultController.sections?[section] {
            return sectionInfo.numberOfObjects
        } else {
            return 0
        }
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
            self.configureCell(cell, atIndexPath: indexPath)
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("BookDownloadingCell", forIndexPath: indexPath)
            self.configureCell(cell, atIndexPath: indexPath)
            return cell
        }
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        if let book = selectedFetchedResultController.objectAtIndexPath(indexPath) as? Book {
            if cell.isKindOfClass(BookOrdinaryCell) {
                let cell = cell as! BookOrdinaryCell
                let indexPathsShouldDisplayDetailDic = segmentedControl.selectedSegmentIndex == 0 ? self.indexPathsShouldDisplayDetailDic["Online"] : self.indexPathsShouldDisplayDetailDic["Local"]
                cell.titleLabel.text = book.title ?? ""
                cell.subtitleLabel.text = indexPathsShouldDisplayDetailDic!.contains(indexPath) ? book.veryDetailedDescription : book.detailedDescription
                cell.hasPicIndicator.backgroundColor = (book.isNoPic?.boolValue ?? true) ? UIColor.lightGrayColor() : Utilities.customTintColor()
                cell.favIcon.image = UIImage(data: book.favIcon ?? NSData())
                cell.indexPath = indexPath
                cell.downloadState = downloadStateOfBook(book)
                cell.delegate = self
            } else if cell.isKindOfClass(BookDownloadingCell) {
                let cell = cell as! BookDownloadingCell
                cell.titleLabel.text = book.title ?? ""
                cell.dateLabel.text = book.dateFormatted
                cell.articleLabel.text = book.articleCountFormatted
                cell.hasPicIndicator.backgroundColor = (book.isNoPic?.boolValue ?? true) ? UIColor.lightGrayColor() : Utilities.customTintColor()
                cell.favIcon.image = UIImage(data: book.favIcon ?? NSData())
                cell.downloadState = downloadStateOfBook(book)
                cell.indexPath = indexPath
                cell.delegate = self
                if let totalBytesWritten = Downloader.sharedInstance.totalBytesWrittenDic[book.idString!], fileSize = book.fileSize?.longLongValue {
                    if shouldRefreshDownloadProgress {
                        cell.progressView.setProgress(Float(totalBytesWritten)/Float(fileSize * 1024), animated: false)
                        cell.fileSizeLabel.text = Utilities.formattedFileSizeStringFromByteCount(totalBytesWritten) + " of " + Utilities.formattedFileSizeStringFromByteCount(fileSize * 1024)
                    }
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
            if let header = view as? UITableViewHeaderFooterView {
                header.textLabel!.font = UIFont.boldSystemFontOfSize(14)
            }
        }
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let cancelAction = UITableViewRowAction(style: .Destructive, title: "Cancel") { (action, indexPath) -> Void in
            if let book = self.selectedFetchedResultController.objectAtIndexPath(indexPath) as? Book {
                Downloader.sharedInstance.cancelDownloadBook(book)
            }
        }
        return [cancelAction]
    }
    
    // MARK: Helper
    
    func tableFooterView() -> UIView {
        let count = self.selectedFetchedResultController.fetchedObjects!.count
        let availableSpaceFormatted = Utilities.formattedFileSizeStringFromByteCount(Utilities.availableDiskspaceInBytes())
        let message: String = {
            if segmentedControl.selectedSegmentIndex == 0 {
                switch count {
                case 0:
                    return "No book available for download\n\(availableSpaceFormatted) available"
                case 1:
                    return "1 book available for download\n\(availableSpaceFormatted) available"
                default:
                    return "\(count) books available for download\n\(availableSpaceFormatted) available"
                }
            } else if segmentedControl.selectedSegmentIndex == 1 {
                switch count {
                case 0:
                    return "No book is downloading"
                case 1:
                    return "1 book is downloading" + "\n\nApp can be minimized at any time, but please do not force quit the app to allow ongoing task to continue in the background."
                default:
                    return "\(count) books are downloading" + "\n\nApp can be minimized at any time, but please do not force quit the app to allow ongoing task to continue in the background."
                }
            } else {
                switch count {
                case 0:
                    return "No book is on device" + "\n\n You can also add file through iTunes File Sharing.\nAll Files here will automatically become searchable and readable"
                case 1:
                    return "1 book on device"  + "\n\n You can also add file through iTunes File Sharing.\nAll Files here will automatically become searchable and readable"
                default:
                    return "\(count) books are on device"  + "\n\n You can also add file through iTunes File Sharing.\nAll Files here will automatically become searchable and readable"
                }
            }
        }()
        
        return Utilities.tableHeaderFooterView(withMessage: message, preferredWidth: preferredContentSize.width, textAlientment: .Center)
    }
    
    func downloadStateOfBook(book: Book) -> BookDownloadState {
        let bookSizeInBytes = book.fileSize!.longLongValue * 1024
        let freeSpaceInBytes = Utilities.availableDiskspaceInBytes()
        switch book.downloadState!.integerValue {
        case 1:
            return .CanPause
        case 2:
            return .CanResume
        case 3:
            return .Finished
        default:
            if Int64(0.8 * Double(freeSpaceInBytes)) > bookSizeInBytes {
                return .GoAhead
            } else if freeSpaceInBytes < bookSizeInBytes{
                return .NotAllowed
            } else {
                return .WithCaution
            }
        }
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
        fetchRequest.predicate = NSPredicate(format: "downloadState > 0 AND downloadState < 3", argumentArray: nil)
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
        fetchRequest.predicate = NSPredicate(format: "downloadState = 3", argumentArray: nil)
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
        
        let isNotLocalPredicate = NSPredicate(format: "downloadState = 0", argumentArray: nil)
        
        if let langCompoundPredicate = langCompoundPredicate {
            return NSCompoundPredicate(andPredicateWithSubpredicates: [langCompoundPredicate, isNotLocalPredicate])
        } else {
            return isNotLocalPredicate
        }
    }
    
    func performFetch() {
        NSFetchedResultsController.deleteCacheWithName("DownloadFetchedResultsController")
        NSFetchedResultsController.deleteCacheWithName("LocalFetchedResultsController")
        NSFetchedResultsController.deleteCacheWithName("OnlineFetchedResultsController")
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
                self.configureCell(tableView.cellForRowAtIndexPath(indexPath!)!, atIndexPath: indexPath!)
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
        refreshTableView()
    }
    
    @IBAction func dismissSelf(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
