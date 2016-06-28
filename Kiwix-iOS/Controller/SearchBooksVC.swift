//
//  SearchBooksVC.swift
//  Kiwix
//
//  Created by Chris Li on 4/7/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import CoreData

class SearchBooksVC: UIViewController, UITableViewDelegate, UITableViewDataSource, TableCellDelegate, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var recentSearchBarHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = UIView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        recentSearchBarHeight.constant = Preference.recentSearchTerms.count == 0 ? 0.0 : 44.0
    }
    
    // MARK: - Fetched Results Controller
    
    let managedObjectContext = UIApplication.appDelegate.managedObjectContext
    lazy var fetchedResultController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Book")
        let langDescriptor = NSSortDescriptor(key: "language.name", ascending: true)
        let titleDescriptor = NSSortDescriptor(key: "title", ascending: true)
        fetchRequest.sortDescriptors = [langDescriptor, titleDescriptor]
        fetchRequest.predicate = NSPredicate(format: "isLocal == true")
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "language.name", cacheName: "ScopeFRC")
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
        self.configureBookCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureBookCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        guard let book = fetchedResultController.objectAtIndexPath(indexPath) as? Book else {return}
        guard let cell = cell as? CheckMarkBookCell else {return}
        
        cell.delegate = self
        cell.titleLabel.text = book.title
        cell.subtitleLabel.text = book.detailedDescription

        cell.favIcon.image = UIImage(data: book.favIcon ?? NSData())
        cell.hasPic = book.hasPic
        cell.hasIndex = book.hasIndex
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
        guard let mainVC = parentViewController?.parentViewController as? MainVC,
            let book = fetchedResultController.objectAtIndexPath(indexPath) as? Book else {return}
        mainVC.hideSearch()
        mainVC.loadMainPage(book)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
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
            self.configureBookCell(tableView.cellForRowAtIndexPath(indexPath!)!, atIndexPath: indexPath!)
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
}
