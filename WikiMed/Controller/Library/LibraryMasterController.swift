//
//  LibraryMasterController.swift
//  Kiwix
//
//  Created by Chris Li on 10/12/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import CoreData

class LibraryMasterController: BaseController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate {
    let tableView = UITableView(frame: .zero, style: .grouped)
    let categories: [BookCategory] = [
        .wikipedia, .wikivoyage, .wikibooks, .wikiversity, .wikispecies, .wikinews,
        .vikidia, .ted, .stackExchange, .gutenberg, .other]
    let categoryImages = [#imageLiteral(resourceName: "Wikipedia"), #imageLiteral(resourceName: "Wikivoyage"), #imageLiteral(resourceName: "Wikibooks"), #imageLiteral(resourceName: "Wikiversity"), #imageLiteral(resourceName: "Wikispecies"), #imageLiteral(resourceName: "Wikinews"), #imageLiteral(resourceName: "Vikidia"), #imageLiteral(resourceName: "TED"), #imageLiteral(resourceName: "StackExchange"), #imageLiteral(resourceName: "Gutenberg"), #imageLiteral(resourceName: "Other")]
    let categoryNames = [
        NSLocalizedString("Wikipedia", comment: "Zim File Types"),
        NSLocalizedString("Wikivoyage", comment: "Zim File Types"),
        NSLocalizedString("Wikibooks", comment: "Zim File Types"),
        NSLocalizedString("Wikiversity", comment: "Zim File Types"),
        NSLocalizedString("Wikispecies", comment: "Zim File Types"),
        NSLocalizedString("Wikinews", comment: "Zim File Types"),
        NSLocalizedString("Vikidia", comment: "Zim File Types"),
        NSLocalizedString("TED", comment: "Zim File Types"),
        NSLocalizedString("StackExchange", comment: "Zim File Types"),
        NSLocalizedString("Gutenberg", comment: "Zim File Types"),
        NSLocalizedString("Other", comment: "Zim File Types")]
    
    override func loadView() {
        view = tableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.register(LibraryBookCell.self, forCellReuseIdentifier: "BookCell")
        tableView.register(LibraryCategoryCell.self, forCellReuseIdentifier: "CategoryCell")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Library", comment: "Library title")
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
        }
    }
    
    // MARK: - UITableViewDataSource & Delegates
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultControllerSectionCount + 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section < fetchedResultControllerSectionCount {
            return fetchedResultController.sections?[section].numberOfObjects ?? 0
        } else {
            return categories.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section < fetchedResultControllerSectionCount {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.text = "Placeholder Title"
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath) as! LibraryCategoryCell
            cell.accessoryType = .disclosureIndicator
            cell.titleLabel.text = categoryNames[indexPath.row]
            cell.logoView.image = categoryImages[indexPath.row]
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section < fetchedResultControllerSectionCount {
            guard let sectionTitle = fetchedResultController.sections?[section].name else {return nil}
            switch sectionTitle {
            case "1":
                return NSLocalizedString("Downloading", comment: "Library section headers")
            case "2":
                return NSLocalizedString("On Device", comment: "Library section headers")
            default:
                return nil
            }
        } else {
            return NSLocalizedString("Categories", comment: "Library section headers")
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let split = splitViewController as? LibraryController {
            split.detail.prepare(category: categories[indexPath.row], name: categoryNames[indexPath.row])
            showDetailViewController(UINavigationController(rootViewController: split.detail), sender: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    // MARK: - NSFetchedResultsController
    
    private let managedObjectContext = AppDelegate.persistentContainer.viewContext
    private lazy var fetchedResultController: NSFetchedResultsController<Book> = {
        let fetchRequest = Book.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "stateRaw", ascending: true),
            NSSortDescriptor(key: "title", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "stateRaw == 1 OR stateRaw == 2")
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                    managedObjectContext: self.managedObjectContext,
                                                    sectionNameKeyPath: "stateRaw", cacheName: nil)
        controller.delegate = self
        try? controller.performFetch()
        return controller as! NSFetchedResultsController<Book>
    }()
    private var fetchedResultControllerSectionCount: Int {
        return fetchedResultController.sections?.count ?? 0
    }
}

