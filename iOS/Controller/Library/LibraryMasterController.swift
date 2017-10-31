//
//  LibraryMasterController.swift
//  Kiwix
//
//  Created by Chris Li on 10/12/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import CoreData
import ProcedureKit

class LibraryMasterController: BaseController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate {
    let tableView = UITableView(frame: .zero, style: .grouped)
    let refreshControl = UIRefreshControl()
    private lazy var onboardingView = OnboardingView()
    let queue = ProcedureQueue()
    
    let categories: [BookCategory] = [
        .wikipedia, .wikivoyage, .wikibooks, .wikiversity, .wikispecies, .wikinews,
        .vikidia, .ted, .stackExchange, .other]
    let categoryImages = [#imageLiteral(resourceName: "Wikipedia"), #imageLiteral(resourceName: "Wikivoyage"), #imageLiteral(resourceName: "Wikibooks"), #imageLiteral(resourceName: "Wikiversity"), #imageLiteral(resourceName: "Wikispecies"), #imageLiteral(resourceName: "Wikinews"), #imageLiteral(resourceName: "Vikidia"), #imageLiteral(resourceName: "TED"), #imageLiteral(resourceName: "StackExchange"), #imageLiteral(resourceName: "Other")]
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
        NSLocalizedString("Other", comment: "Zim File Types")]
    
    let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 1
        formatter.maximumIntegerDigits = 3
        formatter.minimumFractionDigits = 2
        formatter.maximumIntegerDigits = 2
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Library", comment: "Library title")
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
        }
        
        if Preference.libraryLastRefreshTime == nil {
            configureInitialRefreshView()
        } else {
            configureTableView()
        }
    }
    
    private func configureInitialRefreshView() {
        onboardingView.button.addTarget(self, action: #selector(refreshControlPulled), for: .touchUpInside)
        onboardingView.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .groupTableViewBackground
        view.addSubview(onboardingView)
        view.addConstraints([
            view.readableContentGuide.leftAnchor.constraint(equalTo: onboardingView.leftAnchor, constant: 0),
            view.readableContentGuide.rightAnchor.constraint(equalTo: onboardingView.rightAnchor, constant: 0)])
        view.addConstraints([view.centerYAnchor.constraint(equalTo: onboardingView.centerYAnchor, constant: 0)])
    }
    
    private func removeInitialRefreshView() {
        onboardingView.button.removeTarget(self, action: #selector(refreshControlPulled), for: .touchUpInside)
        onboardingView.removeFromSuperview()
    }
    
    private func configureTableView() {
        refreshControl.addTarget(self, action: #selector(refreshControlPulled), for: .valueChanged)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.refreshControl = refreshControl
        tableView.register(LibraryBookCell.self, forCellReuseIdentifier: "BookCell")
        tableView.register(LibraryCategoryCell.self, forCellReuseIdentifier: "CategoryCell")
        view.addSubview(tableView)
        view.addConstraints([
            view.leftAnchor.constraint(equalTo: tableView.leftAnchor),
            view.rightAnchor.constraint(equalTo: tableView.rightAnchor),
            view.topAnchor.constraint(equalTo: tableView.topAnchor),
            view.bottomAnchor.constraint(equalTo: tableView.bottomAnchor)])
    }
    
    @objc func refreshControlPulled() {
        let procedure = LibraryRefreshProcedure()
        procedure.add(observer: WillExecuteObserver(willExecute: { (_, event) in
            OperationQueue.main.addOperation({
                self.onboardingView.button.isEnabled = false
            })
        }))
        procedure.add(observer: DidFinishObserver(didFinish: { (procedure, errors) in
            OperationQueue.main.addOperation({
                if errors.count > 0 {
                    self.onboardingView.button.isEnabled = true
                } else {
                    if self.view.subviews.contains(self.onboardingView) {
                        self.removeInitialRefreshView()
                        self.configureTableView()
                    }
                    self.refreshControl.endRefreshing()
                }
            })
        }))
        queue.add(operation: procedure)
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
            let cell = tableView.dequeueReusableCell(withIdentifier: "BookCell", for: indexPath) as! LibraryBookCell
            configure(bookCell: cell, indexPath: indexPath)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath) as! LibraryCategoryCell
            cell.accessoryType = .disclosureIndicator
            cell.titleLabel.text = categoryNames[indexPath.row]
            cell.logoView.image = categoryImages[indexPath.row]
            return cell
        }
    }
    
    func configure(bookCell cell: LibraryBookCell, indexPath: IndexPath, animated: Bool = false) {
        let book = fetchedResultController.object(at: indexPath)
        cell.titleLabel.text = book.title
        cell.subtitleLabel.text = ["\(book.stateRaw)", book.fileSizeDescription, book.dateDescription, book.articleCountDescription].flatMap({$0}).joined(separator: ", ")
        cell.logoView.image = UIImage(data: book.favIcon ?? Data())
        cell.accessoryType = .disclosureIndicator
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section < fetchedResultControllerSectionCount {
            guard let sectionTitle = fetchedResultController.sections?[section].name else {return nil}
            switch sectionTitle {
            case "1":
                return NSLocalizedString("Downloads", comment: "Library section headers")
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
        if indexPath.section < fetchedResultControllerSectionCount {
            let controller = LibraryBookDetailController(book: fetchedResultController.object(at: indexPath))
            showDetailViewController(UINavigationController(rootViewController: controller), sender: nil)
        } else {
            let controller = LibraryCategoryController(category: categories[indexPath.row], title: categoryNames[indexPath.row])
            showDetailViewController(UINavigationController(rootViewController: controller), sender: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    // MARK: - NSFetchedResultsController
    
    private let managedObjectContext = CoreDataContainer.shared.viewContext
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
            guard let indexPath = indexPath, let cell = tableView.cellForRow(at: indexPath) as? LibraryBookCell else {return}
            configure(bookCell: cell, indexPath: indexPath, animated: true)
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

private class OnboardingView: UIStackView {
    let button = RoundedButton()
    
    init() {
        super.init(frame: .zero)
        configure()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
    
    private func configure() {
        let imageView: UIImageView = {
            let imageView = UIImageView(image: #imageLiteral(resourceName: "Library").withRenderingMode(.alwaysTemplate))
            imageView.contentMode = .scaleAspectFit
            imageView.tintColor = UIColor.gray
            return imageView
        }()
        
        let label: UILabel = {
            let label = UILabel()
            label.text = NSLocalizedString("Refresh library to see all books available for download or import zim files using iTunes File Sharing.", comment: "Empty Library Help")
            label.textAlignment = .center
            label.adjustsFontSizeToFitWidth = true
            label.textColor = UIColor.gray
            label.numberOfLines = 0
            return label
        }()
        
        button.setTitle(NSLocalizedString("Refresh Library", comment: "Empty Library Action"), for: .normal)
        button.setTitle(NSLocalizedString("Refreshing...", comment: "Empty Library Action"), for: .disabled)
        
        axis = .vertical
        distribution = .equalCentering
        spacing = 20
        [imageView, label, button].forEach { (view) in
            addArrangedSubview(view)
        }
    }
}
