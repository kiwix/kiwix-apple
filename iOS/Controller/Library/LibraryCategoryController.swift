//
//  LibraryCategoryController.swift
//  Kiwix
//
//  Created by Chris Li on 10/12/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import CoreData
import SwiftyUserDefaults

class LibraryCategoryController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate {
    let tableView = UITableView()
    private(set) var category: BookCategory?
    
    convenience init(category: BookCategory?, title: String?) {
        self.init()
        self.category = category
        self.title = title
    }
    
    override func loadView() {
        view = tableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.register(TableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.separatorInset = UIEdgeInsets(top: 0, left: tableView.separatorInset.left + 42, bottom: 0, right: 0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "Globe"), style: .plain, target: self, action: #selector(languageFilterBottonTapped(sender:)))
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // if have refreshed library but have not shown language filter alert, show it
        if Defaults[.libraryLastRefreshTime] != nil && !Defaults[.libraryHasShownLanguageFilterAlert] {
            showLanguageFilter()
        }
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .always
        }
    }
    
    @objc func languageFilterBottonTapped(sender: UIBarButtonItem) {
        let controller = LibraryLanguageController()
        controller.dismissBlock = {[unowned self] in
            self.reloadFetchedResultController()
        }
        let navigation = UINavigationController(rootViewController: controller)
        navigation.modalPresentationStyle = .popover
        navigation.popoverPresentationController?.barButtonItem = sender
        present(navigation, animated: true, completion: nil)
    }
    
    private func showLanguageFilter() {
        let deviceLanguageCodes = Locale.preferredLanguages.flatMap({ $0.components(separatedBy: "-").first })
        let deviceLanguageNames: [String] = {
            let names = NSMutableOrderedSet()
            deviceLanguageCodes.flatMap({ (Locale.current as NSLocale).displayName(forKey: .identifier, value: $0) }).forEach({ names.add($0) })
            return names.flatMap({ $0 as? String})
        }()
        
        let message = String(format: NSLocalizedString("You have set %@ as the preferred language(s) of the device. Would you like to hide books in other languages?", comment: "Language Filter"), deviceLanguageNames.joined(separator: ", "))
        
        func handleAlertAction(onlyShowDeviceLanguage: Bool) {
            let context = CoreDataContainer.shared.viewContext
            let languages = Language.fetchAll(context: context)
            if onlyShowDeviceLanguage {
                languages.forEach({ $0.isDisplayed = deviceLanguageCodes.contains($0.code) })
            } else {
                languages.forEach({$0.isDisplayed = false})
            }
            if context.hasChanges {
                try? context.save()
            }
            self.reloadFetchedResultController()
        }
        
        let alert = UIAlertController(title: NSLocalizedString("Language Filter", comment: "Language Filter"), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Hide Other Language", comment: "Language Filter"), style: .default, handler: { (action) in
            handleAlertAction(onlyShowDeviceLanguage: true)
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Skip and Show All", comment: "Language Filter"), style: .default, handler: { (action) in
            handleAlertAction(onlyShowDeviceLanguage: false)
        }))
        present(alert, animated: true)
        Defaults[.libraryHasShownLanguageFilterAlert] = true
    }
    
    // MARK: - UITableViewDataSource & Delagates
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultController.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultController.sections?[section].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TableViewCell
        configure(cell: cell, indexPath: indexPath)
        return cell
    }
    
    func configure(cell: TableViewCell, indexPath: IndexPath, animated: Bool = false) {
        let book = fetchedResultController.object(at: indexPath)
        cell.titleLabel.text = book.title
        cell.detailLabel.text = [book.fileSizeDescription, book.dateDescription, book.articleCountDescription].flatMap({$0}).joined(separator: ", ")
        cell.thumbImageView.image = UIImage(data: book.favIcon ?? Data())
        cell.thumbImageView.contentMode = .scaleAspectFit
        cell.accessoryType = .disclosureIndicator
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return fetchedResultController.sections?[section].name
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return numberOfSections(in: tableView) > 5 ? fetchedResultController.sectionIndexTitles : nil
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return fetchedResultController.section(forSectionIndexTitle: title, at: index)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let controller = LibraryBookDetailController(book: fetchedResultController.object(at: indexPath))
        navigationController?.pushViewController(controller, animated: true)
    }
    
    // MARK: - NSFetchedResultsController
    
    private let managedObjectContext = CoreDataContainer.shared.viewContext
    private lazy var fetchedResultController: NSFetchedResultsController<Book> = {
        let fetchRequest = Book.fetchRequest()
        let langDescriptor = NSSortDescriptor(key: "language.name", ascending: true)
        let titleDescriptor = NSSortDescriptor(key: "title", ascending: true)
        fetchRequest.sortDescriptors = [langDescriptor, titleDescriptor]
        fetchRequest.predicate = self.predicate
        fetchRequest.fetchBatchSize = 20
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                    managedObjectContext: self.managedObjectContext,
                                                    sectionNameKeyPath: "language.name", cacheName: nil)
        controller.delegate = self
        try? controller.performFetch()
        return controller as! NSFetchedResultsController<Book>
    }()
    
    private var predicate: NSCompoundPredicate {
        let displayedLanguages = Language.fetch(displayed: true, context: managedObjectContext)
        var subpredicates = [NSPredicate]()
        if displayedLanguages.count > 0 {
            subpredicates.append(NSPredicate(format: "language IN %@", displayedLanguages))
        } else {
            subpredicates.append(NSPredicate(format: "language.name != nil"))
        }
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
            guard let indexPath = indexPath, let cell = tableView.cellForRow(at: indexPath) as? TableViewCell else {return}
            configure(cell: cell, indexPath: indexPath, animated: true)
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

