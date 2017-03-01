//
//  BookmarkBooksController.swift
//  Kiwix
//
//  Created by Chris Li on 1/11/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import CoreData

class BookmarkBooksController: CoreDataTableBaseController, UITableViewDelegate, UITableViewDataSource {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Bookmarks"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "showBookmarks",
            let navController = segue.destination as? UINavigationController,
            let controller = navController.topViewController as? BookmarkCollectionController else {return}
        guard let cell = sender as? UITableViewCell,
            let indexPath = tableView.indexPath(for: cell) else {return}
        controller.book = fetchedResultController.object(at: indexPath)
    }


    @IBAction func dismiss(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - TableView Data Source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultController.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionInfo = fetchedResultController.sections?[section] else {return 0}
        return sectionInfo.numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    override func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath, animated: Bool = false) {
        guard let cell = cell as? BasicBookCell else {return}
        let book = fetchedResultController.object(at: indexPath)
        
        cell.titleLabel.text = book.title
        cell.hasPic = book.hasPic
        cell.favIcon.image = UIImage(data: book.favIcon ?? Data())
        cell.subtitleLabel.text = book.detailedDescription
        cell.accessoryType = splitViewController?.traitCollection.horizontalSizeClass == .compact ? .disclosureIndicator : .none
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let stateRaw = fetchedResultController.sections?[section].name, let stateInt = Int(stateRaw) else {return nil}
        return BookState(rawValue: stateInt)?.description
    }
    
    // MARK: - TableView Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Fetched Results Controller

    let managedObjectContext = AppDelegate.persistentContainer.viewContext
    lazy var fetchedResultController: NSFetchedResultsController<Book> = {
        let fetchRequest = Book.fetchRequest()
        let stateDescriptor = NSSortDescriptor(key: "stateRaw", ascending: true)
        let titleDescriptor = NSSortDescriptor(key: "title", ascending: true)
        fetchRequest.sortDescriptors = [stateDescriptor, titleDescriptor]
        fetchRequest.predicate = NSPredicate(format: "stateRaw >= 2")
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "stateRaw", cacheName: "BookmarkBooksFRC" + Bundle.buildVersion)
        fetchedResultsController.delegate = self
        try? fetchedResultsController.performFetch()
        return fetchedResultsController as! NSFetchedResultsController<Book>
    }()

}
