//
//  CloudBooksController.swift
//  Kiwix
//
//  Created by Chris Li on 8/17/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import CoreData
import ProcedureKit
import MBProgressHUD
import DZNEmptyDataSet

class CloudBooksController: LibraryBaseController, LanguageFilterUpdating, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    private(set) var isRefreshing = false // used to control text on empty table view
    private(set) var isOnScreen = false // used to determine if should delay showing lang filter alert
    private(set) var langFilterAlertPending = false
    
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
        
        let inset = UIEdgeInsets(top: 0, left: 0, bottom: tabBarController!.tabBar.frame.height, right: 0)
        tableView.contentInset = inset
        tableView.scrollIndicatorInsets = inset
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
                let indexPath = tableView.indexPath(for: cell) else {return}
            let book = fetchedResultController.object(at: indexPath)
            bookDetailController.book = book
        default:
            break
        }
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
        operation.add(observer: WillExecuteObserver { (operation) in
            OperationQueue.main.addOperation({
                // Configure empty table data set, so it shows "Refreshing..."
                self.isRefreshing = true
                self.tableView.reloadEmptyDataSet()
            })
        })
        operation.add(observer: DidFinishObserver { (operation, errors) in
            guard let operation = operation as? RefreshLibraryOperation else {return}
            OperationQueue.main.addOperation({ 
                defer {
                    self.refreshControl?.endRefreshing()
                    self.isRefreshing = false
                    self.tableView.reloadEmptyDataSet()
                }
                
                if let error =  errors.first {
                    // handle error [network, xmlparse]
                } else {
                    if operation.firstTime {
                        //self.showLanguageFilterAlert()
                        //self.configureNavBarButtons()
                    } else {
                        self.showRefreshSuccessMessage()
                    }
                }
            })
        })
        GlobalQueue.shared.add(operation: operation)
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
//        let operation = NetworkRequiredAlert(context: self)
//        GlobalQueue.shared.addOperation(operation)
    }
    
    func showLanguageFilterAlert() {
//        guard isOnScreen else {
//            langFilterAlertPending = true
//            return
//        }
//        let handler: (AlertOperation<UIViewController>) -> Void = { [weak self] _ in
//            let context = NSManagedObjectContext.mainQueueContext
//            context.performBlock({
//                let codes = NSLocale.preferredLangCodes
//                Language.fetchAll(context).forEach({ (language) in
//                    language.isDisplayed = codes.contains(language.code)
//                })
//                _ = try? context.save()
//                self?.refreshFetchedResultController()
//            })
//        }
//        let operation = LanguageFilterAlert(context: self, handler: handler)
//        GlobalQueue.shared.addOperation(operation)
//        langFilterAlertPending = false
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
    
    override func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        guard let cell = cell as? BasicBookCell else {return}
        let book = fetchedResultController.object(at: indexPath)
        
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
        cell.accessoryType = splitViewController?.traitCollection.horizontalSizeClass == .compact ? .disclosureIndicator : .none
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
        let book = fetchedResultController.object(at: indexPath)
        switch book.spaceState {
        case .enough:
            let action = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: LocalizedStrings.download, handler: { _ in
//                guard let download = DownloadBookOperation(bookID: book.id) else {return}
//                Network.shared.queue.addOperation(download)
            })
            action.backgroundColor = UIColor.defaultTint
            return [action]
        case .caution:
            let action = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: LocalizedStrings.download, handler: { _ in
//                let alert = SpaceCautionAlert(context: self, bookID: book.id)
//                GlobalQueue.shared.addOperation(alert)
                self.tableView.setEditing(false, animated: true)
            })
            action.backgroundColor = UIColor.orange
            return [action]
        case .notEnough:
            let action = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: LocalizedStrings.spaceNotEnough, handler: { _ in
//                let alert = SpaceNotEnoughAlert(context: self)
//                GlobalQueue.shared.addOperation(alert)
                self.tableView.setEditing(false, animated: true)
            })
            return [action]
        }
    }
    
    // MARK: - Fetched Results Controller
    
    let managedObjectContext = AppDelegate.persistentContainer.viewContext
    lazy var fetchedResultController: NSFetchedResultsController<Book> = {
        let fetchRequest = Book.fetchRequest()
        let langDescriptor = NSSortDescriptor(key: "language.name", ascending: true)
        let titleDescriptor = NSSortDescriptor(key: "title", ascending: true)
        fetchRequest.sortDescriptors = [langDescriptor, titleDescriptor]
        fetchRequest.predicate = self.onlineCompoundPredicate
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "language.name", cacheName: "OnlineFRC" + Bundle.buildVersion)
        fetchedResultsController.delegate = self
        fetchedResultsController.performFetch(deleteCache: false)
        return fetchedResultsController as! NSFetchedResultsController<Book>
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
        let isCloudPredicate = NSPredicate(format: "stateRaw == 0")
        return NSCompoundPredicate(andPredicateWithSubpredicates: [langPredicate, isCloudPredicate])
    }
    
}
