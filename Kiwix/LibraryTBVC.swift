//
//  LibraryTBVC.swift
//  Kiwix
//
//  Created by Chris on 12/12/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit
import CoreData

class LibraryTBVC: UITableViewController, NSFetchedResultsControllerDelegate, LibraryRefresherDelegate, BookTableCellDelegate {

    var cloudDetailBooks = Set<Book>()
    var localDetailBooks = Set<Book>()
    var tableViewTopIndexPaths = [NSIndexPath]()
    var previouslySelectedSegmentIndex = 0
    var progressShouldUpdate = true
    var timerProgress = NSTimer()
    var timerLabel = NSTimer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        UIApplication.libraryRefresher.delegate = self
        UIApplication.downloader.delegate = self
        
        timerProgress = NSTimer.scheduledTimerWithTimeInterval(0.75, target: self, selector: "resetProgressUpdateTimer", userInfo: nil, repeats: true)
        timerLabel = NSTimer.scheduledTimerWithTimeInterval(60.0, target: self, selector: "refreshMessageLabelText", userInfo: nil, repeats: true)
        showPreferredLanguageAlertIfNeeded()
        configureToolBar(animated: false)
        tableView.reloadData()
        
        UIApplication.appDelegate.networkTaskCount += UIApplication.downloader.taskCount
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        UIApplication.libraryRefresher.delegate = nil
        UIApplication.downloader.delegate = nil
        
        timerProgress.invalidate()
        timerLabel.invalidate()
        
        UIApplication.appDelegate.networkTaskCount -= UIApplication.downloader.taskCount
    }
    
    func resetProgressUpdateTimer() {
        progressShouldUpdate = true
    }
    
    // MARK: - Fetched Result Controller
    
    let managedObjectContext = UIApplication.appDelegate.managedObjectContext
    var selectedFetchedResultController: NSFetchedResultsController {
        switch segmentedControl.selectedSegmentIndex {
        case 0: return onlineFetchedResultController
        case 1: return downloadFetchedResultController
        default: return localFetchedResultController
        }
    }
    
    private var langPredicate: NSPredicate {
        let displayedLanguages = Language.fetch(displayed: true, context: self.managedObjectContext)
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
    
    lazy var onlineFetchedResultController: NSFetchedResultsController = {
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
    
    lazy var downloadFetchedResultController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "DownloadTask")
        let creationTimeDescriptor = NSSortDescriptor(key: "creationTime", ascending: true)
        fetchRequest.sortDescriptors = [creationTimeDescriptor]
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: "DownloadFRC")
        fetchedResultsController.delegate = self
        fetchedResultsController.performFetch(deleteCache: false)
        return fetchedResultsController
    }()
    
    lazy var localFetchedResultController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Book")
        let langDescriptor = NSSortDescriptor(key: "language.name", ascending: true)
        let titleDescriptor = NSSortDescriptor(key: "title", ascending: true)
        fetchRequest.sortDescriptors = [langDescriptor, titleDescriptor]
        fetchRequest.predicate = NSPredicate(format: "isLocal == true")
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "language.name", cacheName: "LocalFRC")
        fetchedResultsController.delegate = self
        fetchedResultsController.performFetch(deleteCache: false)
        return fetchedResultsController
    }()
    
    func refreshOnlineFetchedResultController() {
        onlineFetchedResultController.fetchRequest.predicate = onlineCompoundPredicate
        onlineFetchedResultController.performFetch(deleteCache: true)
        tableView.reloadData()
    }
    
    // MARK: - BarButtonItems
    
    lazy var cloudMessageItem: MessageBarButtonItem = MessageBarButtonItem()
    lazy var downloadMessageItem: MessageBarButtonItem = MessageBarButtonItem()
    lazy var localMessageItem: MessageBarButtonItem = MessageBarButtonItem()
    lazy var refreshLibButton: UIBarButtonItem = UIBarButtonItem(imageNamed: "Refresh", target: self, action: "refreshLibrary:")
    lazy var langFilterButton: UIBarButtonItem = UIBarButtonItem(imageNamed: "LanguageFilter", target: self, action: "showLangFilter:")
    lazy var pauseAllButton: UIBarButtonItem = UIBarButtonItem(imageNamed: "Refresh", target: self, action: "refreshLibrary:")
    lazy var resumeAllButton: UIBarButtonItem = UIBarButtonItem(imageNamed: "Refresh", target: self, action: "refreshLibrary:")
    lazy var cellularButton: UIBarButtonItem = UIBarButtonItem(imageNamed: "Refresh", target: self, action: "refreshLibrary:")
    lazy var wifiButton: UIBarButtonItem = UIBarButtonItem(imageNamed: "Refresh", target: self, action: "refreshLibrary:")
    lazy var scanButton: UIBarButtonItem = UIBarButtonItem(imageNamed: "Refresh", target: self, action: "refreshLibrary:")
    lazy var editButton: UIBarButtonItem = UIBarButtonItem(imageNamed: "Refresh", target: self, action: "refreshLibrary:")
    lazy var spaceBarButtonItem = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace)
    
    // MARK: - Controls and Actions

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    
    @IBAction func segmentedControlValueChanged(sender: UISegmentedControl) {
        tableView.reloadData()
        configureToolBar(animated: true)
//        if tableView.numberOfSections > 0 {
//            if tableView.numberOfRowsInSection(0) > 0 {
//                tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: .Top, animated: false)
//            }
//        }
    }
    
    @IBAction func dismissButtonTapped(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

}
