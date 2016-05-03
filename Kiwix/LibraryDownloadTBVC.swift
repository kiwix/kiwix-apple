//
//  LibraryDownloadTBVC.swift
//  Kiwix
//
//  Created by Chris Li on 2/11/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import CoreData

class LibraryDownloadTBVC: UITableViewController, NSFetchedResultsControllerDelegate, BookTableCellDelegate, DownloadProgressReporting, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    // MARK: - Override
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.tableFooterView = UIView()
        
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        
        configureToolBar()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        segmentedControl.selectedSegmentIndex = 1
        Network.sharedInstance.delegate = self
        refreshProgress(animated: false)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        Network.sharedInstance.delegate = nil
    }
    
    // MARK: - BookTableCellDelegate
    
    func didTapOnAccessoryViewForCell(cell: BookTableCell) {
        guard let indexPath = tableView.indexPathForCell(cell),
            let downloadTask = fetchedResultController.objectAtIndexPath(indexPath) as? DownloadTask,
            let book = downloadTask.book else {return}
        switch downloadTask.state {
        case .Downloading:
            Network.sharedInstance.pause(book)
        case .Paused, .Error:
            Network.sharedInstance.resume(book)
        default:
            break
        }
    }
    
    // MARK: -  DownloadProgressReporting
    
    func refreshProgress(animated animated: Bool) {
        guard let downloadTasks = fetchedResultController.fetchedObjects as? [DownloadTask] else {return}
        for downloadTask in downloadTasks {
            guard let id = downloadTask.book?.id,
                let indexPath = fetchedResultController.indexPathForObject(downloadTask),
                let cell = tableView.cellForRowAtIndexPath(indexPath) as? DownloadBookCell,
                let progress = Network.sharedInstance.progresses[id] else {return}
            cell.progressView.setProgress(Float(progress.fractionCompleted), animated: animated)
            cell.subtitleLabel.text = progress.description
        }
    }
    
    // MARK: - ToolBar Button
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBAction func segmentedControlValueChanged(sender: UISegmentedControl) {
        tabBarController?.selectedIndex = sender.selectedSegmentIndex
    }
    @IBAction func dismissSelf(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    var messageButton = MessageBarButtonItem()
    
    func configureToolBar() {
        guard var toolBarItems = self.toolbarItems else {return}
        toolBarItems[1] = messageButton
        setToolbarItems(toolBarItems, animated: false)
        
        configureToolBarVisibility(animated: false)
        configureMessage()
    }
    
    func configureToolBarVisibility(animated animated: Bool) {
        navigationController?.setToolbarHidden(fetchedResultController.fetchedObjects?.count == 0, animated: animated)
    }
    
    func configureMessage() {
        guard let count = fetchedResultController.fetchedObjects?.count else {return}
        let localizedString = String.localizedStringWithFormat(NSLocalizedString("%d download tasks", comment: "Book Library, book downloader message"), count)
        messageButton.text = localizedString
    }
    
    // MARK: - Empty table datasource & delegate
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "DownloadColor")
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text = NSLocalizedString("No Download Task", comment: "Book Library, book downloader, no book center title")
        let attributes = [NSFontAttributeName: UIFont.boldSystemFontOfSize(18.0),
                          NSForegroundColorAttributeName: UIColor.darkGrayColor()]
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text = NSLocalizedString("After starting a download task, minimize the app to continue the task in the background.", comment: "Book Library, book downloader, no book center description")
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .ByWordWrapping
        style.alignment = .Center
        let attributes = [NSFontAttributeName: UIFont.boldSystemFontOfSize(14.0),
                          NSForegroundColorAttributeName: UIColor.lightGrayColor(),
                          NSParagraphStyleAttributeName: style]
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    func buttonTitleForEmptyDataSet(scrollView: UIScrollView!, forState state: UIControlState) -> NSAttributedString! {
        let text = NSLocalizedString("Learn more", comment: "Book Library, book downloader, learn more button text")
        let attributes = [NSFontAttributeName: UIFont.boldSystemFontOfSize(17.0), NSForegroundColorAttributeName: segmentedControl.tintColor]
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    func spaceHeightForEmptyDataSet(scrollView: UIScrollView!) -> CGFloat {
        return 30.0
    }
    
    func emptyDataSetDidTapButton(scrollView: UIScrollView!) {
        guard let navController = UIStoryboard.setting.instantiateViewControllerWithIdentifier("WebViewNav") as? UINavigationController,
            let controller = navController.topViewController as? WebViewVC else {return}
        controller.page = .DownloaderLearnMore
        presentViewController(navController, animated: true, completion: nil)
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
        let cellIdentifier = "Cell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath)
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        guard let downloadTask = fetchedResultController.objectAtIndexPath(indexPath) as? DownloadTask,
              let book = downloadTask.book, let id = book.id,
              let cell = cell as? DownloadBookCell else {return}
        
        cell.titleLabel.text = book.title
        cell.hasPicIndicator.backgroundColor = book.hasPic ? UIColor.havePicTintColor : UIColor.lightGrayColor()
        cell.favIcon.image = UIImage(data: book.favIcon ?? NSData())
        cell.dateLabel.text = book.dateFormatted
        cell.articleCountLabel.text = book.articleCountFormatted
        cell.delegate = self
        
        guard let progress = Network.sharedInstance.progresses[id] else {return}
        cell.progressView.progress = Float(progress.fractionCompleted)
        
        switch downloadTask.state {
        case .Queued, .Downloading:
            cell.accessoryImageView.highlighted = false
            cell.accessoryImageTintColor = UIColor.orangeColor().colorWithAlphaComponent(0.75)
        case .Paused, .Error:
            cell.accessoryImageView.highlighted = true
            cell.accessoryHighlightedImageTintColor = UIColor.greenColor().colorWithAlphaComponent(0.75)
        }
        cell.subtitleLabel.text = progress.description
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
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard tableView.numberOfSections > 1 else {return 0.0}
        guard let headerText = self.tableView(tableView, titleForHeaderInSection: section) else {return 0.0}
        guard headerText != "" else {return 0.0}
        return 20.0
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else {return}
        header.textLabel?.font = UIFont.boldSystemFontOfSize(14)
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {}
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let remove = UITableViewRowAction(style: .Destructive, title: LocalizedStrings.remove) { (action, indexPath) -> Void in
            guard let downloadTask = self.fetchedResultController.objectAtIndexPath(indexPath) as? DownloadTask,
                  let book = downloadTask.book else {return}
            Network.sharedInstance.cancel(book)
            book.isLocal = false
            let context = UIApplication.appDelegate.managedObjectContext
            context.performBlockAndWait({ () -> Void in
                book.isLocal = false
                context.deleteObject(downloadTask)
            })
            
        }
        return [remove]
    }
    
    // MARK: - Fetched Results Controller
    
    let managedObjectContext = UIApplication.appDelegate.managedObjectContext
    lazy var fetchedResultController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "DownloadTask")
        let creationTimeDescriptor = NSSortDescriptor(key: "creationTime", ascending: true)
        fetchRequest.sortDescriptors = [creationTimeDescriptor]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: "DownloadFRC")
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
        configureToolBarVisibility(animated: true)
        configureMessage()
    }
}
