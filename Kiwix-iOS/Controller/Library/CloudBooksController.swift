//
//  CloudBooksController.swift
//  Kiwix
//
//  Created by Chris Li on 8/17/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import CoreData
import Operations
import MBProgressHUD
import DZNEmptyDataSet

class CloudBooksController: UITableViewController, NSFetchedResultsControllerDelegate, LanguageFilterUpdating, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    private(set) var isRefreshing = false
    
    // MARK: - Override
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        tabBarItem.title = LocalizedStrings.LibraryTabTitle.cloud
        tabBarItem.image = UIImage(named: "Cloud")
        tabBarItem.selectedImage = UIImage(named: "CloudFilled")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.tableFooterView = UIView()
        
        refreshControl = RefreshLibControl()
        refreshControl?.addTarget(self, action: #selector(CloudBooksController.refresh), forControlEvents: .ValueChanged)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.navigationItem.rightBarButtonItem = UIBarButtonItem(imageNamed: "LanguageFilter", target: self, action: #selector(CloudBooksController.showLanguageFilter))
        refreshAutomatically()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else {return}
        switch identifier {
        case "ShowBookDetail":
            guard let navController = segue.destinationViewController as? UINavigationController,
                let bookDetailController = navController.topViewController as? BookDetailController,
                let cell = sender as? UITableViewCell,
                let indexPath = tableView.indexPathForCell(cell),
                let book = fetchedResultController.objectAtIndexPath(indexPath) as? Book else {return}
            bookDetailController.book = book
        default:
            break
        }
    }
    
    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        let top = tabBarController!.navigationController!.navigationBar.frame.maxY
        let bottom = tabBarController!.tabBar.frame.height
        let inset = UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
        tableView.contentInset = inset
        tableView.scrollIndicatorInsets = inset
    }
    
    // MARK: - Actions
    
    func showLanguageFilter() {
        guard let splitViewController = splitViewController as? LibrarySplitViewController where !splitViewController.isShowingLangFilter else {return}
        guard let controller = UIStoryboard.library.initViewController(LanguageFilterController.self) else {return}
        controller.delegate = self
        let navController = UINavigationController(rootViewController: controller)
        showDetailViewController(navController, sender: self)
        
        guard let indexPath = tableView.indexPathForSelectedRow else {return}
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func refreshAutomatically() {
        guard let date = Preference.libraryLastRefreshTime else {
            refresh(invokedByUser: false)
            return
        }
        guard date.timeIntervalSinceNow < -86400 else {return}
        refresh(invokedByUser: false)
    }
    
    func refresh(invokedByUser invokedByUser: Bool) {
        let operation = RefreshLibraryOperation()
        operation.addObserver(WillExecuteObserver { (operation) in
            NSOperationQueue.mainQueue().addOperationWithBlock({
                self.isRefreshing = true
                self.tableView.reloadEmptyDataSet()
            })
        })
        
        operation.addObserver(DidFinishObserver { (operation, errors) in
            guard let operation = operation as? RefreshLibraryOperation else {return}
            NSOperationQueue.mainQueue().addOperationWithBlock({
                defer {
                    self.refreshControl?.endRefreshing()
                    self.isRefreshing = false
                    self.tableView.reloadEmptyDataSet()
                }
                
                if errors.count > 0 {
                    if let error = errors.first as? ReachabilityCondition.Error
                        where error == ReachabilityCondition.Error.NotReachable && invokedByUser == true {
                        self.showReachibilityAlert()
                    }
                } else{
                    if operation.firstTime {
                        self.showLanguageFilterAlert()
                    } else {
                        self.showRefreshSuccessMessage()
                    }
                }
            })
        })
        GlobalQueue.shared.addOperation(operation)
    }
    
    func showRefreshSuccessMessage() {
        guard let view = self.splitViewController?.view else {return}
        let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        hud.mode = .Text
        hud.label.numberOfLines = 0
        hud.label.text = NSLocalizedString("Library is refreshed successfully!", comment: "Cloud Book Controller")
        hud.hideAnimated(true, afterDelay: 2)
    }
    
    func showReachibilityAlert() {
        let cancel = UIAlertAction(title: LocalizedStrings.Common.ok, style: .Cancel, handler: nil)
        let alertController = UIAlertController(title: NSLocalizedString("Network Required", comment: "Network Required Alert"),
                                                message: NSLocalizedString("Unable to connect to server. Please check your Internet connection.", comment: "Network Required Alert"),
                                                preferredStyle: .Alert)
        alertController.addAction(cancel)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func showLanguageFilterAlert() {
        var names = NSLocale.preferredLangNames
        guard let last = names.popLast() else {return}
        var parts = [String]()
        if names.count > 0 { parts.append(names.joinWithSeparator(", ")) }
        parts.append(last)
        let string = parts.joinWithSeparator(" and ")
    
        let comment = "Library: Language Filter Alert"
        let alert = UIAlertController(title: NSLocalizedString("Only Show Preferred Language?", comment: comment),
                                      message: NSLocalizedString(String(format: "Would you like to filter the library by %@?", string), comment: comment),
                                      preferredStyle: .Alert)
        let action = UIAlertAction(title: LocalizedStrings.Common.yes, style: .Default) { (action) in
            self.managedObjectContext.performBlock({
                let codes = NSLocale.preferredLangCodes
                Language.fetchAll(self.managedObjectContext).forEach({ (language) in
                    language.isDisplayed = codes.contains(language.code)
                })
                self.refreshFetchedResultController()
            })
        }
        alert.addAction(action)
        alert.addAction(UIAlertAction(title: LocalizedStrings.Common.cancel, style: .Cancel, handler: nil))
        alert.preferredAction = action
        presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: - LanguageFilterUpdating
    
    func languageFilterChanged() {
        guard isViewLoaded() && view.window != nil else {return}
        refreshFetchedResultController()
    }
    
    func languageFilterFinsihEditing(hasChanges: Bool) {
        guard hasChanges else {return}
        refreshFetchedResultController()
    }
    
    // MARK: - TableView Data Source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultController.sections?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultController.sections?[section].numberOfObjects ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        guard let book = fetchedResultController.objectAtIndexPath(indexPath) as? Book else {return}
        guard let cell = cell as? BasicBookCell else {return}
        
        let textColor: UIColor = {
            switch book.spaceState {
            case .Enough:
                return UIColor.blackColor()
            case .Caution:
                return UIColor.orangeColor()
            case .NotEnough:
                return UIColor.grayColor()
            }
        }()
        
        cell.hasPic = book.hasPic
        cell.hasIndex = book.hasIndex
        cell.favIcon.image = UIImage(data: book.favIcon ?? NSData())
        cell.titleLabel.text = book.title
        cell.subtitleLabel.text = [
            book.dateDescription,
            book.fileSizeDescription,
            book.articleCountDescription
        ].flatMap({$0}).joinWithSeparator("  ")
        cell.titleLabel.textColor = textColor
        cell.subtitleLabel.textColor = textColor
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
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]?{
        guard let book = fetchedResultController.objectAtIndexPath(indexPath) as? Book else {return nil}
        switch book.spaceState {
        case .Enough:
            let action = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: LocalizedStrings.download, handler: { _ in
                guard let download = DownloadBookOperation(bookID: book.id) else {return}
                Network.shared.queue.addOperation(download)
            })
            action.backgroundColor = UIColor.defaultTint
            return [action]
        case .Caution:
            let action = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: LocalizedStrings.download, handler: { _ in
                let alert = SpaceCautionAlert(context: self, bookID: book.id)
                GlobalQueue.shared.addOperation(alert)
                self.tableView.setEditing(false, animated: true)
            })
            action.backgroundColor = UIColor.orangeColor()
            return [action]
        case .NotEnough:
            let action = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: LocalizedStrings.Library.spaceNotEnough, handler: { _ in
                let alert = SpaceNotEnoughAlert(context: self)
                GlobalQueue.shared.addOperation(alert)
                self.tableView.setEditing(false, animated: true)
            })
            return [action]
        }
    }
    
    // MARK: - Fetched Results Controller
    
    let managedObjectContext = NSManagedObjectContext.mainQueueContext
    lazy var fetchedResultController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Book")
        let langDescriptor = NSSortDescriptor(key: "language.name", ascending: true)
        let titleDescriptor = NSSortDescriptor(key: "title", ascending: true)
        fetchRequest.sortDescriptors = [langDescriptor, titleDescriptor]
        fetchRequest.predicate = self.onlineCompoundPredicate
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "language.name", cacheName: "OnlineFRC" + NSBundle.buildVersion)
        fetchedResultsController.delegate = self
        fetchedResultsController.performFetch(deleteCache: false)
        return fetchedResultsController
    }()
    
    func refreshFetchedResultController() {
        fetchedResultController.fetchRequest.predicate = onlineCompoundPredicate
        fetchedResultController.performFetch(deleteCache: true)
        tableView.reloadData()
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
