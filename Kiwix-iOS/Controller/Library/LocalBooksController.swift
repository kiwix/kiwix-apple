//
//  LocalBooksController.swift
//  Kiwix
//
//  Created by Chris Li on 8/23/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import CoreData
import ProcedureKit
import DZNEmptyDataSet

class LocalBooksController: UITableViewController, NSFetchedResultsControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    // MARK: - Override
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        tabBarItem.title = LocalizedStrings.local
        tabBarItem.image = UIImage(named: "Folder")
        tabBarItem.selectedImage = UIImage(named: "FolderFilled")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.tableFooterView = UIView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.title = tabBarItem.title
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
    
    // MARK: - TableView Data Source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultController.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionInfo = fetchedResultController.sections?[section] else {return 0}
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        guard let cell = cell as? BasicBookCell else {return}
        let book = fetchedResultController.object(at: indexPath)
        
        cell.titleLabel.text = book.title
        cell.hasPic = book.hasPic
        cell.favIcon.image = UIImage(data: book.favIcon ?? Data())
        cell.subtitleLabel.text = book.detailedDescription
    }
    
    // MARK: Other Data Source
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let stateRaw = fetchedResultController.sections?[section].name else {return nil}
        switch stateRaw {
        case "2":
            return LocalizedStrings.local
        case "3":
            return NSLocalizedString("Retained by Bookmarks", comment: "Library, local tab")
        case "4":
            return NSLocalizedString("Purgeable", comment: "Library, local tab")
        default:
            return nil
        }
    }
    
    // MARK: - Table View Delegate
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let stateRaw = fetchedResultController.sections?[section].name else {return 0.0}
        return (section == 0 && stateRaw == "2") ? 0.0 : 20.0
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else {return}
        header.textLabel?.font = UIFont.boldSystemFont(ofSize: 14)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {}
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: LocalizedStrings.remove) { (action, indexPath) -> Void in
            let book = self.fetchedResultController.object(at: indexPath)
            // this is where the delete book confirm alert will come in replace of DeleteBookFileOperation
            let operation = DeleteBookFileOperation(zimID: book.id)
            GlobalQueue.shared.add(operation: operation)
            self.tableView.setEditing(false, animated: true)
        }
        return [delete]
    }
    
    // MARK: - Fetched Results Controller
    
    let managedObjectContext = AppDelegate.persistentContainer.viewContext
    lazy var fetchedResultController: NSFetchedResultsController<Book> = {
        let fetchRequest = Book.fetchRequest()
        let stateDescriptor = NSSortDescriptor(key: "stateRaw", ascending: true)
        let titleDescriptor = NSSortDescriptor(key: "title", ascending: true)
        fetchRequest.sortDescriptors = [stateDescriptor, titleDescriptor]
        fetchRequest.predicate = NSPredicate(format: "stateRaw >= 2")
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "stateRaw", cacheName: "LocalFRC" + Bundle.buildVersion)
        fetchedResultsController.delegate = self
        fetchedResultsController.performFetch(deleteCache: false)
        return fetchedResultsController as! NSFetchedResultsController<Book>
    }()
    
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
