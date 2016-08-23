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

class CloudBooksController: UITableViewController, NSFetchedResultsControllerDelegate, LanguageFilterUpdating {
    
    // MARK: - Override
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        title = ""
        tabBarItem.title = LocalizedStrings.LibraryTabTitle.cloud
        tabBarItem.image = UIImage(named: "Cloud")
        tabBarItem.selectedImage = UIImage(named: "CloudFilled")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = RefreshLibControl()
        refreshControl?.addTarget(self, action: #selector(CloudBooksController.refresh), forControlEvents: .ValueChanged)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.navigationItem.rightBarButtonItem = UIBarButtonItem(imageNamed: "LanguageFilter", target: self, action: #selector(CloudBooksController.showLanguageFilter))
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
    
    // MARK: - Actions
    
    func showLanguageFilter() {
        guard let splitViewController = splitViewController as? LibrarySplitViewController where !splitViewController.isShowingLangFilter else {return}
        guard let controller = UIStoryboard.libraryNew.initViewController(LanguageFilterController.self) else {return}
        controller.delegate = self
        let navController = UINavigationController(rootViewController: controller)
        showDetailViewController(navController, sender: self)
        
        guard let indexPath = tableView.indexPathForSelectedRow else {return}
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func refresh() {
        let operation = RefreshLibraryOperation()
        operation.addObserver(DidFinishObserver { operation in
            NSOperationQueue.mainQueue().addOperationWithBlock({
                self.refreshControl?.endRefreshing()
            })
        })
        GlobalOperationQueue.sharedInstance.addOperation(operation)
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
        
        cell.titleLabel.text = book.title
        cell.hasPic = book.hasPic
        cell.hasIndex = false
        cell.favIcon.image = UIImage(data: book.favIcon ?? NSData())
        cell.subtitleLabel.text = book.detailedDescription
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

class RefreshLibControl: UIRefreshControl {
    
    static let pullDownToRefresh = NSLocalizedString("Pull Down To Refresh", comment: "Refresh Library Control")
    static let lastRefresh = NSLocalizedString("Last Refresh", comment: "Refresh Library Control")
    
    override var hidden: Bool {
        didSet {
            guard hidden != oldValue && hidden == false else {return}
            updateTitle()
        }
    }
    
    private func updateTitle() {
        let string: String = {
            guard let lastRefreshTime = Preference.libraryLastRefreshTime else {return RefreshLibControl.pullDownToRefresh}
            let formatter = NSDateFormatter()
            formatter.dateFormat = "MMM d, h:mm a"
            return "Last Refresh" + ": " + formatter.stringFromDate(lastRefreshTime)
        }()
        let attributes = [NSForegroundColorAttributeName: UIColor.blackColor()]
        attributedTitle = NSAttributedString(string: string, attributes: attributes)
    }
}

