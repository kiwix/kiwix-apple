//
//  LibraryCategoryController.swift
//  Kiwix
//
//  Created by Chris Li on 10/12/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import CoreData

class LibraryCategoryController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate {
    let tableView = UITableView()
    var category: BookCategory? {
        didSet {
            reloadFetchedResultController()
        }
    }
    
    override func loadView() {
        view = tableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(LibraryBookCell.self, forCellReuseIdentifier: "Cell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    // MARK: - UITableViewDataSource & Delagates
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultController.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultController.sections?[section].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! LibraryBookCell
        
        let book = fetchedResultController.object(at: indexPath)
        cell.titleLabel.text = book.title
        cell.subtitleLabel.text = [book.fileSizeDescription, book.dateDescription, book.articleCountDescription].flatMap({$0}).joined(separator: ", ")
        cell.logoView.image = UIImage(data: book.favIcon ?? Data())
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return fetchedResultController.sections?[section].name
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    // MARK: - NSFetchedResultsController
    
    private let managedObjectContext = AppDelegate.persistentContainer.viewContext
    private lazy var fetchedResultController: NSFetchedResultsController<Book> = {
        let fetchRequest = Book.fetchRequest()
        let langDescriptor = NSSortDescriptor(key: "language.name", ascending: true)
        let titleDescriptor = NSSortDescriptor(key: "title", ascending: true)
        fetchRequest.sortDescriptors = [langDescriptor, titleDescriptor]
        fetchRequest.predicate = self.predicate
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                    managedObjectContext: self.managedObjectContext,
                                                    sectionNameKeyPath: "language.name", cacheName: nil)
        controller.delegate = self
        try? controller.performFetch()
        return controller as! NSFetchedResultsController<Book>
    }()
    
    private var predicate: NSCompoundPredicate {
        let displayedLanguages = Language.fetch(displayed: true, context: managedObjectContext)
        var subpredicates = [
            NSPredicate(format: "stateRaw == 0"),
            displayedLanguages.count > 0 ? NSPredicate(format: "language IN %@", displayedLanguages) : NSPredicate(format: "language.name != nil")
        ]
        if let category = category {
            subpredicates.append(NSPredicate(format: "category == %@", category.rawValue))
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: subpredicates)
    }
    
    func reloadFetchedResultController() {
        fetchedResultController.fetchRequest.predicate = predicate
        try? fetchedResultController.performFetch()
        tableView.reloadData()
    }
}

