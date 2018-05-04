//
//  LibraryMasterController.swift
//  Kiwix
//
//  Created by Chris Li on 10/12/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import CoreData
import RealmSwift
import ProcedureKit

class LibraryMasterController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate {
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let refreshControl = UIRefreshControl()
    private var sections: [Section] = [.category]
    private let categories: [ZimFile.Category] = [
        .wikipedia, .wikivoyage, .wikibooks, .wikiversity, .wikispecies, .wikinews,
        .vikidia, .ted, .stackExchange, .other]
    
    // MARK: - Database
    
    private let localZimFiles: Results<ZimFile>? = {
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            let predicate = NSPredicate(format: "stateRaw == %@", ZimFile.State.local.rawValue)
            return database.objects(ZimFile.self).filter(predicate)
        } catch { return nil }
    }()
    private var localZimFilesChangeToken: NotificationToken?
    
    // MARK: - Overrides
    
    override func loadView() {
        view = tableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.refreshControl = refreshControl
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.register(TableViewCell.self, forCellReuseIdentifier: "LocalZimFileCell")
        tableView.register(LibraryDownloadCell.self, forCellReuseIdentifier: "DownloadTaskCell")
        tableView.register(TableViewCell.self, forCellReuseIdentifier: "CategoryCell")
        tableView.separatorInset = UIEdgeInsets(top: 0, left: tableView.separatorInset.left + 42, bottom: 0, right: 0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Library", comment: "Library title")
        refreshControl.addTarget(self, action: #selector(refreshControlPulled), for: .valueChanged)
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissController))
        
        if splitViewController?.traitCollection.horizontalSizeClass == .regular {
            let firstIndexPath = IndexPath(row: 0, section: 0)
            tableView.delegate?.tableView?(tableView, didSelectRowAt: firstIndexPath)
        }
        
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureSections()
        tableView.reloadData()
        configureChangeToken()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .always
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        localZimFilesChangeToken = nil
    }
    
    // MARK: -
    
    @objc func dismissController() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func refreshControlPulled() {
        let procedure = LibraryRefreshProcedure()
        procedure.add(observer: DidFinishObserver(didFinish: { (procedure, errors) in
            OperationQueue.main.addOperation({
                self.refreshControl.endRefreshing()
            })
        }))
        Queue.shared.add(libraryRefresh: procedure)
    }
    
    private func configureSections() {
        guard let localZimFileCount = localZimFiles?.count else {return}
        if let sectionIndex = sections.index(of: .localZimFile) {
            if localZimFileCount == 0 {
                sections.remove(at: sectionIndex)
            }
        } else {
            if localZimFileCount > 0 {
                sections.insert(.localZimFile, at: 0)
            }
        }
    }
    
    private func configureChangeToken() {
        localZimFilesChangeToken = localZimFiles?.observe({ (changes) in
            switch changes {
            case .update(let results, let deletions, let insertions, let updates):
                self.tableView.beginUpdates()
                
                if results.count > 0, self.sections.index(of: .localZimFile) == nil {
                    self.sections.insert(.localZimFile, at: 0)
                    self.tableView.insertSections(IndexSet([0]), with: .fade)
                }
                
                if let sectionIndex = self.sections.index(of: .localZimFile) {
                    self.tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: sectionIndex) }), with: .fade)
                    self.tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: sectionIndex) }), with: .fade)
                    updates.forEach({ row in
                        let indexPath = IndexPath(row: row, section: sectionIndex)
                        guard let cell = self.tableView.cellForRow(at: indexPath) as? TableViewCell else {return}
                        self.configure(localZimFileCell: cell, row: row)
                    })
                }
                
                if results.count == 0, let sectionIndex = self.sections.index(of: .localZimFile) {
                    self.sections.remove(at: sectionIndex)
                    self.tableView.deleteSections(IndexSet([sectionIndex]), with: .fade)
                }
                
                self.tableView.endUpdates()
            default:
                break
            }
        })
    }
    
    // MARK: - UITableViewDataSource & Delegates
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .localZimFile:
            return localZimFiles?.count ?? 0
        case .downloadTask:
            return 0
        case .category:
            return categories.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch sections[indexPath.section] {
        case .localZimFile:
            let cell = tableView.dequeueReusableCell(withIdentifier: "LocalZimFileCell", for: indexPath) as! TableViewCell
            configure(localZimFileCell: cell, row: indexPath.row)
            return cell
        case .downloadTask:
            let cell = tableView.dequeueReusableCell(withIdentifier: "DownloadTaskCell", for: indexPath) as! TableViewCell
            return cell
        case .category:
            let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath) as! TableViewCell
            let category = categories[indexPath.row]
            cell.accessoryType = .disclosureIndicator
            cell.titleLabel.text = category.description
            cell.thumbImageView.image = category.icon
            cell.thumbImageView.contentMode = .scaleAspectFit
            return cell
        }
    }
    
    func configure(localZimFileCell cell: TableViewCell, row: Int, animated: Bool = false) {
        guard let zimFile = localZimFiles?[row] else {return}
        cell.titleLabel.text = zimFile.title
        cell.detailLabel.text = [zimFile.fileSizeDescription, zimFile.creationDateDescription, zimFile.articleCountDescription].joined(separator: ", ")
        cell.thumbImageView.image = UIImage(data: zimFile.icon)
        cell.thumbImageView.contentMode = .scaleAspectFit
        cell.accessoryType = .disclosureIndicator
    }
    
    func configure(downloadTaskCell cell: LibraryDownloadCell, indexPath: IndexPath, animated: Bool = false) {
//        let book = fetchedResultController.object(at: indexPath)
//        cell.titleLabel.text = book.title
//        cell.stateLabel.text = book.state.shortLocalizedDescription
//        cell.progressLabel.text = [book.totalBytesWritten, book.fileSize].map({ByteCountFormatter.string(fromByteCount: $0, countStyle: .file)}).joined(separator: " / ")
//        cell.logoView.image = UIImage(data: book.favIcon ?? Data())
//        cell.accessoryType = .disclosureIndicator
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch sections[section] {
        case .localZimFile:
            return NSLocalizedString("On Device", comment: "Library section headers")
        case .downloadTask:
            return NSLocalizedString("Downloads", comment: "Library section headers")
        case .category:
            return NSLocalizedString("Categories", comment: "Library section headers")
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
        switch sections[indexPath.section] {
        case .localZimFile:
            break
        case .downloadTask:
            break
        case .category:
            let controller = LibraryCategoryController(category: categories[indexPath.row])
            showDetailViewController(UINavigationController(rootViewController: controller), sender: nil)
        }
//        if indexPath.section < fetchedResultControllerSectionCount {
//            let controller = LibraryBookDetailController(book: fetchedResultController.object(at: indexPath))
//            showDetailViewController(UINavigationController(rootViewController: controller), sender: nil)
//        } else {
//        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    // MARK: - Type Definition
    
    enum Section { case localZimFile, downloadTask, category }
}
