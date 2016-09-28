//
//  SearchBooksController.swift
//  Kiwix
//
//  Created by Chris Li on 4/7/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import CoreData
import DZNEmptyDataSet

class SearchBooksController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, TableCellDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var recentSearchContainer: DropShadowView!
    @IBOutlet weak var recentSearchBarHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
//        tableView.emptyDataSetSource = self
//        tableView.emptyDataSetDelegate = self
        tableView.tableHeaderView = UIView()
        tableView.tableFooterView = UIView()
        tableView.keyboardDismissMode = .OnDrag
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        configureRecentSearchBarHeight()
    }
    
    func configureRecentSearchBarHeight() {
        let previousHeight = recentSearchBarHeight.constant
        let newHeight: CGFloat = Preference.recentSearchTerms.count == 0 ? 0.0 : 44.0
        guard previousHeight != newHeight else {return}
        recentSearchBarHeight.constant = newHeight
        recentSearchContainer.setNeedsDisplay()
    }
    
    // MARK: - Empty table datasource & delegate
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text = NSLocalizedString("No Book Available", comment: "Book Library, book downloader, no book center title")
        let attributes = [NSFontAttributeName: UIFont.boldSystemFontOfSize(18.0),
                          NSForegroundColorAttributeName: UIColor.darkGrayColor()]
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    func buttonTitleForEmptyDataSet(scrollView: UIScrollView!, forState state: UIControlState) -> NSAttributedString! {
        let text = NSLocalizedString("Download A Book", comment: "Book Library, book downloader, learn more button text")
        let attributes = [NSFontAttributeName: UIFont.boldSystemFontOfSize(17.0), NSForegroundColorAttributeName: UIButton().tintColor]
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    func verticalOffsetForEmptyDataSet(scrollView: UIScrollView!) -> CGFloat {
        return -64.0
    }
    
    func spaceHeightForEmptyDataSet(scrollView: UIScrollView!) -> CGFloat {
        return 0.0
    }
    
    func emptyDataSetDidTapButton(scrollView: UIScrollView!) {
    }
    
    // MARK: - Fetched Results Controller
    
    let managedObjectContext = NSManagedObjectContext.mainQueueContext
    lazy var fetchedResultController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Book")
        let langDescriptor = NSSortDescriptor(key: "language.name", ascending: true)
        let titleDescriptor = NSSortDescriptor(key: "title", ascending: true)
        fetchRequest.sortDescriptors = [langDescriptor, titleDescriptor]
        fetchRequest.predicate = NSPredicate(format: "stateRaw == 2")
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: "ScopeFRC" + NSBundle.buildVersion)
        fetchedResultsController.delegate = self
        fetchedResultsController.performFetch(deleteCache: false)
        return fetchedResultsController
    }()
    
    // MARK: - Table Cell Delegate
    
    func didTapOnAccessoryViewForCell(cell: UITableViewCell) {
        guard let indexPath = tableView.indexPathForCell(cell),
            let book = fetchedResultController.objectAtIndexPath(indexPath) as? Book else {return}
        book.includeInSearch = !book.includeInSearch
    }

    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultController.sections?.count ?? 0
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionInfo = fetchedResultController.sections?[section] else {return 0}
        return sectionInfo.numberOfObjects
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("CheckMarkBookCell", forIndexPath: indexPath)
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        guard let book = fetchedResultController.objectAtIndexPath(indexPath) as? Book else {return}
        guard let cell = cell as? CheckMarkBookCell else {return}
        
        cell.delegate = self
        cell.titleLabel.text = book.title
        cell.subtitleLabel.text = book.detailedDescription

        cell.favIcon.image = UIImage(data: book.favIcon ?? NSData())
        cell.hasPic = book.hasPic
        cell.isChecked = book.includeInSearch
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard tableView.numberOfSections > 1 else {return nil}
        guard let languageName = fetchedResultController.sections?[section].name else {return nil}
        return languageName
    }
    
    // MARK: Table view delegate
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let headerText = self.tableView(tableView, titleForHeaderInSection: section) else {return 0.0}
        guard headerText != "" else {return 0.0}
        return 20.0
    }
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else {return}
        header.textLabel?.font = UIFont.boldSystemFontOfSize(14)
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        guard let book = fetchedResultController.objectAtIndexPath(indexPath) as? Book else {return}
        let operation = ArticleLoadOperation(bookID: book.id)
        GlobalQueue.shared.add(load: operation)
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
