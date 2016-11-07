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
    
    fileprivate(set) var isRefreshing = false
    fileprivate(set) var isOnScreen = false
    fileprivate(set) var langFilterAlertPending = false
    
    // MARK: - Override
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        tabBarItem.title = LocalizedStrings.cloud
        tabBarItem.image = UIImage(named: "Cloud")
        tabBarItem.selectedImage = UIImage(named: "CloudFilled")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.tableFooterView = UIView()
            
        refreshControl = RefreshLibControl()
        refreshControl?.addTarget(self, action: #selector(CloudBooksController.refresh), for: .valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.title = tabBarItem.title
        configureNavBarButtons()
        refreshAutomatically()
        isOnScreen = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if langFilterAlertPending {showLanguageFilterAlert()}
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.navigationItem.rightBarButtonItem = nil
        isOnScreen = false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else {return}
        switch identifier {
        case "ShowBookDetail":
            guard let navController = segue.destination as? UINavigationController,
                let bookDetailController = navController.topViewController as? BookDetailController,
                let cell = sender as? UITableViewCell,
                let indexPath = tableView.indexPath(for: cell),
                let book = fetchedResultController.object(at: indexPath) as? Book else {return}
            bookDetailController.book = book
        default:
            break
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        let top = tabBarController!.navigationController!.navigationBar.frame.maxY
        let bottom = tabBarController!.tabBar.frame.height
        let inset = UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
        tableView.contentInset = inset
        tableView.scrollIndicatorInsets = inset
    }
    
    // MARK: - Actions
    
    func showLanguageFilterController() {
        guard let splitViewController = splitViewController as? LibrarySplitViewController, !splitViewController.isShowingLangFilter else {return}
        guard let controller = UIStoryboard.library.initViewController(LanguageFilterController.self) else {return}
        controller.delegate = self
        let navController = UINavigationController(rootViewController: controller)
        showDetailViewController(navController, sender: self)
        
        guard let indexPath = tableView.indexPathForSelectedRow else {return}
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func refreshAutomatically() {
        guard let date = Preference.libraryLastRefreshTime else {
            refresh(invokedByUser: false)
            return
        }
        guard date.timeIntervalSinceNow < -86400 else {return}
        refresh(invokedByUser: false)
    }
    
    func refresh(invokedByUser: Bool) {
        let operation = RefreshLibraryOperation()
        operation.addObserver(WillExecuteObserver { (operation) in
            OperationQueue.mainQueue().addOperationWithBlock({
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
                    if let error = errors.first as? ReachabilityCondition.Error, error == ReachabilityCondition.Error.NotReachable && invokedByUser == true {
                        self.showReachibilityAlert()
                    }
                } else{
                    if operation.firstTime {
                        self.showLanguageFilterAlert()
                        self.configureNavBarButtons()
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
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.mode = .text
        hud.label.numberOfLines = 0
        hud.label.text = NSLocalizedString("Library is refreshed successfully!", comment: "Library, cloud tab")
        hud.hide(animated: true, afterDelay: 2)
    }
    
    func showReachibilityAlert() {
        let operation = NetworkRequiredAlert(context: self)
        GlobalQueue.shared.addOperation(operation)
    }
    
    func showLanguageFilterAlert() {
        guard isOnScreen else {
            langFilterAlertPending = true
            return
        }
        let handler: (AlertOperation<UIViewController>) -> Void = { [weak self] _ in
            let context = NSManagedObjectContext.mainQueueContext
            context.performBlock({
                let codes = NSLocale.preferredLangCodes
                Language.fetchAll(context).forEach({ (language) in
                    language.isDisplayed = codes.contains(language.code)
                })
                _ = try? context.save()
                self?.refreshFetchedResultController()
            })
        }
        let operation = LanguageFilterAlert(context: self, handler: handler)
        GlobalQueue.shared.addOperation(operation)
        langFilterAlertPending = false
    }
    
    func configureNavBarButtons() {
        tabBarController?.navigationItem.rightBarButtonItem = Preference.libraryLastRefreshTime == nil ? nil
            : UIBarButtonItem(imageNamed: "LanguageFilter", target: self, action: #selector(CloudBooksController.showLanguageFilterController))
    }
    
    // MARK: - LanguageFilterUpdating
    
    func languageFilterChanged() {
        guard isViewLoaded && view.window != nil else {return}
        refreshFetchedResultController()
    }
    
    func languageFilterFinsihEditing(_ hasChanges: Bool) {
        guard hasChanges else {return}
        refreshFetchedResultController()
    }
    
    // MARK: - TableView Data Source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultController.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultController.sections?[section].numberOfObjects ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        guard let book = fetchedResultController.object(at: indexPath) as? Book else {return}
        guard let cell = cell as? BasicBookCell else {return}
        
        let textColor: UIColor = {
            switch book.spaceState {
            case .enough:
                return UIColor.black
            case .caution:
                return UIColor.orange
            case .notEnough:
                return UIColor.gray
            }
        }()
        
        cell.hasPic = book.hasPic
        cell.favIcon.image = UIImage(data: book.favIcon ?? Data())
        cell.titleLabel.text = book.title
        cell.subtitleLabel.text = [
            book.dateDescription,
            book.fileSizeDescription,
            book.articleCountDescription
        ].flatMap({$0}).joined(separator: "  ")
        cell.titleLabel.textColor = textColor
        cell.subtitleLabel.textColor = textColor
    }
    
    // MARK: Other Data Source
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard tableView.numberOfSections > 1 else {return nil}
        guard let languageName = fetchedResultController.sections?[section].name else {return nil}
        return languageName
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        let sectionIndexTitles = fetchedResultController.sectionIndexTitles
        guard sectionIndexTitles.count > 2 else {return nil}
        return sectionIndexTitles
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return fetchedResultController.section(forSectionIndexTitle: title, at: index)
    }
    
    // MARK: - Table View Delegate
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard tableView.numberOfSections > 1 else {return 0.0}
        guard let headerText = self.tableView(tableView, titleForHeaderInSection: section) else {return 0.0}
        guard headerText != "" else {return 0.0}
        return 20.0
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else {return}
        header.textLabel?.font = UIFont.boldSystemFont(ofSize: 14)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {}
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?{
        guard let book = fetchedResultController.object(at: indexPath) as? Book else {return nil}
        switch book.spaceState {
        case .enough:
            let action = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: LocalizedStrings.download, handler: { _ in
                guard let download = DownloadBookOperation(bookID: book.id) else {return}
                Network.shared.queue.addOperation(download)
            })
            action.backgroundColor = UIColor.defaultTint
            return [action]
        case .caution:
            let action = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: LocalizedStrings.download, handler: { _ in
                let alert = SpaceCautionAlert(context: self, bookID: book.id)
                GlobalQueue.shared.addOperation(alert)
                self.tableView.setEditing(false, animated: true)
            })
            action.backgroundColor = UIColor.orange
            return [action]
        case .notEnough:
            let action = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: LocalizedStrings.spaceNotEnough, handler: { _ in
                let alert = SpaceNotEnoughAlert(context: self)
                GlobalQueue.shared.addOperation(alert)
                self.tableView.setEditing(false, animated: true)
            })
            return [action]
        }
    }
    
    // MARK: - Fetched Results Controller
    
    let managedObjectContext = NSManagedObjectContext.mainQueueContext
    lazy var fetchedResultController: NSFetchedResultsController = { () -> <<error type>> in 
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Book")
        let langDescriptor = NSSortDescriptor(key: "language.name", ascending: true)
        let titleDescriptor = NSSortDescriptor(key: "title", ascending: true)
        fetchRequest.sortDescriptors = [langDescriptor, titleDescriptor]
        fetchRequest.predicate = self.onlineCompoundPredicate
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "language.name", cacheName: "OnlineFRC" + Bundle.buildVersion)
        fetchedResultsController.delegate = self
        fetchedResultsController.performFetch(deleteCache: false)
        return fetchedResultsController
    }()
    
    func refreshFetchedResultController() {
        fetchedResultController.fetchRequest.predicate = onlineCompoundPredicate
        fetchedResultController.performFetch(deleteCache: true)
        tableView.reloadData()
    }
    
    fileprivate var langPredicate: NSPredicate {
        let displayedLanguages = Language.fetch(displayed: true, context: managedObjectContext)
        if displayedLanguages.count > 0 {
            return NSPredicate(format: "language IN %@", displayedLanguages)
        } else {
            return NSPredicate(format: "language.name != nil")
        }
    }
    
    fileprivate var onlineCompoundPredicate: NSCompoundPredicate {
        let isCloudPredicate = NSPredicate(format: "stateRaw == 0")
        return NSCompoundPredicate(andPredicateWithSubpredicates: [langPredicate, isCloudPredicate])
    }
    
    // MARK: - Fetched Result Controller Delegate
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
            return
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else {return}
            tableView.insertRows(at: [newIndexPath], with: .fade)
        case .delete:
            guard let indexPath = indexPath else {return}
            tableView.deleteRows(at: [indexPath], with: .fade)
        case .update:
            guard let indexPath = indexPath, let cell = tableView.cellForRow(at: indexPath) else {return}
            configureCell(cell, atIndexPath: indexPath)
        case .move:
            guard let indexPath = indexPath, let newIndexPath = newIndexPath else {return}
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.insertRows(at: [newIndexPath], with: .fade)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
}
