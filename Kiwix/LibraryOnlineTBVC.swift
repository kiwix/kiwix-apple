//
//  LibraryOnlineTBVC.swift
//  Kiwix
//
//  Created by Chris Li on 2/8/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import CoreData

class LibraryOnlineTBVC: UITableViewController, NSFetchedResultsControllerDelegate, BookTableCellDelegate, LTBarButtonItemDelegate, RefreshLibraryOperationDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    var booksShowingDetail = Set<Book>()
    weak var refreshOperation: RefreshLibraryOperation?
    var messsageLabelConfigTimer: NSTimer?
    
    // MARK: - Override
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.tableFooterView = UIView()
        
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        
        reconnectToExistingRefreshOperation()
        refreshLibraryForTheFirstTime()
        configureToolBar()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        segmentedControl.selectedSegmentIndex = 0
        configureRefreshStatus()
        messsageLabelConfigTimer = NSTimer.scheduledTimerWithTimeInterval(60.0, target: self, selector: #selector(configureMessage), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        messsageLabelConfigTimer?.invalidate()
    }
    
    
    // MARK: - BookTableCellDelegate
    
    func didTapOnAccessoryViewForCell(cell: BookTableCell) {
        guard let indexPath = tableView.indexPathForCell(cell),
              let book = fetchedResultController.objectAtIndexPath(indexPath) as? Book else {return}
        switch book.spaceState {
        case .Enough:
            Network.sharedInstance.download(book)
        case .Caution:
            // TODO: - Switch to a global op queue
            Network.sharedInstance.operationQueue.addOperation(SpaceCautionAlert(book: book, presentationContext: self))
        case .NotEnough:
            // TODO: - Switch to a global op queue
            Network.sharedInstance.operationQueue.addOperation(SpaceNotEnoughAlert(book: book, presentationContext: self))
        }
    }
    
    // MARK: - LTBarButtonItemDelegate
    
    func barButtonTapped(sender: LTBarButtonItem, gestureRecognizer: UIGestureRecognizer) {
        guard sender === refreshLibButton else {return}
        startRefresh(invokedAutomatically: false)
    }
    
    // MARK: - RefreshLibraryOperationDelegate
    
    func refreshDidStart() {
        configureRefreshStatus()
        configureToolBarVisibility(animated: true)
    }
    
    func refreshDidFinish() {
        configureRefreshStatus()
        configureToolBarVisibility(animated: true)
    }
    
    // MARK: - Others
    
    func reconnectToExistingRefreshOperation() {
        guard let operation = refreshOperation ??
            UIApplication.globalOperationQueue.operation(String(RefreshLibraryOperation)) as? RefreshLibraryOperation
            else {return}
        refreshOperation = operation
        operation.delegate = self
    }
    
    func refreshLibraryForTheFirstTime() {
        guard Preference.libraryLastRefreshTime == nil else {return}
        startRefresh(invokedAutomatically: true)
    }
    
    func startRefresh(invokedAutomatically invokedAutomatically: Bool) {
        let refreshOperation = RefreshLibraryOperation(invokedAutomatically: invokedAutomatically)
        refreshOperation.delegate = self
        UIApplication.globalOperationQueue.addOperation(refreshOperation)
        self.refreshOperation = refreshOperation
    }
    
    // MARK: - ToolBar Button
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBAction func segmentedControlValueChanged(sender: UISegmentedControl) {
        tabBarController?.selectedIndex = sender.selectedSegmentIndex
    }
    @IBAction func dismissSelf(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    lazy var refreshLibButton: LTBarButtonItem = LTBarButtonItem(configure: BarButtonConfig(imageName: "Refresh", delegate: self))
    var messageButton = MessageBarButtonItem()
    
    func configureToolBar() {
        guard var toolBarItems = self.toolbarItems else {return}
        toolBarItems[0] = refreshLibButton
        toolBarItems[2] = messageButton
        
        let negativeSpace = UIBarButtonItem(barButtonSystemItem: .FixedSpace)
        negativeSpace.width = -10
        toolBarItems.insert(negativeSpace, atIndex: 0)
        setToolbarItems(toolBarItems, animated: false)
        
        configureToolBarVisibility(animated: false)
        configureMessage(isRefreshing: false)
    }
    
    func configureToolBarVisibility(animated animated: Bool) {
        navigationController?.setToolbarHidden(fetchedResultController.fetchedObjects?.count == 0, animated: animated)
    }
    
    func configureMessage(isRefreshing isRefreshing: Bool = false) {
        if !isRefreshing {
            guard let sectionInfos = fetchedResultController.sections else {messageButton.text = nil; return}
            let count = sectionInfos.reduce(0) {$0 + $1.numberOfObjects}
            let localizedBookCountString = String.localizedStringWithFormat(NSLocalizedString("%d book(s) available for download", comment: "Book Library, online book catalogue message"), count)
            guard count > 0 else {messageButton.text = localizedBookCountString; return}
            guard let lastRefreshTime = Preference.libraryLastRefreshTime else {messageButton.text = localizedBookCountString; return}
            let localizedRefreshTimeString: String = {
                var string = NSLocalizedString("Last Refresh: ", comment: "Book Library, online book catalogue refresh time")
                if NSDate().timeIntervalSinceDate(lastRefreshTime) > 60.0 {
                    string += lastRefreshTime.timeAgoSinceNow()
                } else {
                    string += NSLocalizedString("just now", comment: "Book Library, online book catalogue refresh time")
                }
                return string
            }()
            messageButton.text = localizedBookCountString + "\n" + localizedRefreshTimeString
        } else {
            messageButton.text = LocalizedStrings.refreshing
        }
    }
    
    func configureRefreshStatus() {
        let executing = refreshOperation?.executing ?? false
        executing ? refreshLibButton.startRotating() : refreshLibButton.stopRotating()
        configureMessage(isRefreshing: executing)
        tableView.reloadEmptyDataSet()
    }
    
    // MARK: - Empty table datasource & delegate
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "CloudColor")
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text = NSLocalizedString("There are some books in the cloud", comment: "Book Library, book online catalogue, no book center title")
        let attributes = [NSFontAttributeName: UIFont.boldSystemFontOfSize(18.0),
                          NSForegroundColorAttributeName: UIColor.darkGrayColor()]
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text = NSLocalizedString("Refresh the library to show all books available for download.", comment: "Book Library, book online catalogue, no book center description")
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .ByWordWrapping
        style.alignment = .Center
        let attributes = [NSFontAttributeName: UIFont.boldSystemFontOfSize(14.0),
                          NSForegroundColorAttributeName: UIColor.lightGrayColor(),
                          NSParagraphStyleAttributeName: style]
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    func buttonTitleForEmptyDataSet(scrollView: UIScrollView!, forState state: UIControlState) -> NSAttributedString! {
        if let _ = refreshOperation {
            let text = NSLocalizedString("Refreshing...", comment: "Book Library, book downloader, refreshing button text")
            let attributes = [NSFontAttributeName: UIFont.boldSystemFontOfSize(17.0), NSForegroundColorAttributeName: UIColor.darkGrayColor()]
            return NSAttributedString(string: text, attributes: attributes)
        } else {
            let text = NSLocalizedString("Refresh Now", comment: "Book Library, book downloader, refresh now button text")
            let attributes = [NSFontAttributeName: UIFont.boldSystemFontOfSize(17.0), NSForegroundColorAttributeName: segmentedControl.tintColor]
            return NSAttributedString(string: text, attributes: attributes)
        }
    }
    
    func verticalOffsetForEmptyDataSet(scrollView: UIScrollView!) -> CGFloat {
        return -64.0
    }
    
    func spaceHeightForEmptyDataSet(scrollView: UIScrollView!) -> CGFloat {
        return 30.0
    }
    
    func emptyDataSetDidTapButton(scrollView: UIScrollView!) {
        guard self.refreshOperation == nil else {return}
        startRefresh(invokedAutomatically: false)
    }
    
    // MARK: - TableView Data Source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultController.sections?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultController.sections?[section].numberOfObjects ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "Cell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath)
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        guard let book = fetchedResultController.objectAtIndexPath(indexPath) as? Book else {return}
        guard let cell = cell as? CloudBookCell else {return}
        
        cell.titleLabel.text = book.title
        cell.hasPicIndicator.backgroundColor = book.hasPic ? UIColor.havePicTintColor : UIColor.lightGrayColor()
        cell.favIcon.image = UIImage(data: book.favIcon ?? NSData())
        cell.delegate = self
        cell.subtitleLabel.text = booksShowingDetail.contains(book) ? book.detailedDescription2 : book.detailedDescription
        
        switch book.spaceState {
        case .Enough:
            cell.accessoryImageTintColor = UIColor.greenColor().colorWithAlphaComponent(0.75)
        case .Caution:
            cell.accessoryImageTintColor = UIColor.orangeColor().colorWithAlphaComponent(0.75)
        case .NotEnough:
            cell.accessoryImageTintColor = UIColor.grayColor().colorWithAlphaComponent(0.75)
        }
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
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let book = fetchedResultController.objectAtIndexPath(indexPath) as? Book else {return}
        if booksShowingDetail.contains(book) {
            booksShowingDetail.remove(book)
        } else {
            booksShowingDetail.insert(book)
        }
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }
    
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
    
    // MARK: - Fetched Results Controller
    
    let managedObjectContext = UIApplication.appDelegate.managedObjectContext
    lazy var fetchedResultController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Book")
        let langDescriptor = NSSortDescriptor(key: "language.name", ascending: true)
        let titleDescriptor = NSSortDescriptor(key: "title", ascending: true)
        fetchRequest.sortDescriptors = [langDescriptor, titleDescriptor]
        fetchRequest.predicate = self.onlineCompoundPredicate
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "language.name", cacheName: "OnlineFRC")
        fetchedResultsController.delegate = self
        fetchedResultsController.performFetch(deleteCache: false)
        return fetchedResultsController
    }()
    
    func refreshFetchedResultController() {
        fetchedResultController.fetchRequest.predicate = onlineCompoundPredicate
        fetchedResultController.performFetch(deleteCache: true)
        tableView.reloadData()
        configureMessage(isRefreshing: false)
    }
    
    private var langPredicate: NSPredicate {
        let displayedLanguages = Language.fetch(displayed: true, context: managedObjectContext)
        if displayedLanguages.count > 0 {
            return NSPredicate(format: "language IN %@", displayedLanguages)
        } else {
            return NSPredicate(format: "language.name != nil")
        }
    }
    
    private var onlineCompoundPredicate: NSCompoundPredicate {
        let isCloudPredicate = NSPredicate(format: "isLocal == false")
        return NSCompoundPredicate(andPredicateWithSubpredicates: [langPredicate, isCloudPredicate])
    }
    
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
    }
}
