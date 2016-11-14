//
//  DownloadController.swift
//  Kiwix
//
//  Created by Chris Li on 8/24/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import CoreData
import DZNEmptyDataSet

class DownloadTasksController: CDBC, UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    var timer: Timer?
    
    // MARK: - Override
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        tabBarItem.title = LocalizedStrings.download
        tabBarItem.image = UIImage(named: "Download")
        tabBarItem.selectedImage = UIImage(named: "DownloadFilled")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.tableFooterView = UIView()
        
        tableView.estimatedRowHeight = 90.0
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.title = tabBarItem.title
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(DownloadTasksController.refreshProgress), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
        timer = nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else {return}
        switch identifier {
        case "ShowBookDetail":
            guard let navController = segue.destination as? UINavigationController,
                let bookDetailController = navController.topViewController as? BookDetailController,
                let cell = sender as? UITableViewCell,
                let indexPath = tableView.indexPath(for: cell),
                let downloadTask = fetchedResultController.object(at: indexPath) as? DownloadTask,
                let book = downloadTask.book else {return}
            bookDetailController.book = book
        default:
            break
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        let top = tabBarController!.navigationController!.navigationBar.frame.maxY
        let bottom = tabBarController!.tabBar.frame.height
        let inset = UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
        tableView.contentInset = inset
        tableView.scrollIndicatorInsets = inset
    }
    
    // MARK: - Methods
    
    func refreshProgress() {
        tableView.visibleCells.forEach { (cell) in
            guard let indexPath = tableView.indexPath(for: cell) else {return}
            configureCell(cell, atIndexPath: indexPath, animated: true)
        }
    }
    
    func refreshTabBarBadgeCount() {
        guard let count = fetchedResultController.fetchedObjects?.count else {return}
        tabBarItem.badgeValue = count > 0 ? "\(count)" : nil
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
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath, animated: Bool = false) {
        guard let downloadTask = fetchedResultController.object(at: indexPath) as? DownloadTask,
            let book = downloadTask.book,
            let cell = cell as? DownloadBookCell else {return}
        
        cell.titleLabel.text = book.title
        cell.favIcon.image = UIImage(data: book.favIcon ?? Data())
        
//        if let progress = Network.shared.operations[book.id]?.progress {
//            cell.progressLabel.text = progress.fractionCompletedDescription
//            cell.progressView.setProgress(Float(progress.fractionCompleted), animated: animated)
//            cell.detailLabel.text = {
//                let string = progress.progressAndSpeedDescription
//                if downloadTask.state == .downloading {
//                    if string.contains(" — ") {
//                        return string.replacingOccurrences(of: " — ", with: "\n")
//                    } else {
//                        return string + "\n" + NSLocalizedString("Estimating", comment: "Library, download tab")
//                    }
//                } else {
//                    return string + "\n" + String(downloadTask.state)
//                }
//            }()
//        } else {
//            let progress = Double(downloadTask.totalBytesWritten) / Double(book.fileSize)
//            cell.progressLabel.text = DownloadTask.percentFormatter.string(from: NSNumber(value: progress as Double))
//            cell.progressView.setProgress(Float(progress), animated: animated)
//            cell.detailLabel.text = {
//                let downloadedSize = ByteCountFormatter.string(fromByteCount: downloadTask.totalBytesWritten, countStyle: .file)
//                let fileSize = book.fileSizeDescription
//                return String(format: NSLocalizedString("%@ of %@ completed", comment: "Library, download tab"), downloadedSize, fileSize)
//                    + "\n" + String(downloadTask.state)
//            }()
//        }
    }
    
    // MARK: Other Data Source
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard tableView.numberOfSections > 1 else {return nil}
        guard let languageName = fetchedResultController.sections?[section].name else {return nil}
        return languageName
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        let sectionIndexTitles = fetchedResultController.sectionIndexTitles
        guard sectionIndexTitles.count > 2 else {return nil}
        return sectionIndexTitles
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return fetchedResultController.section(forSectionIndexTitle: title, at: index)
    }
    
    // MARK: - Table View Delegate
    
//    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        guard tableView.numberOfSections > 1 else {return 0.0}
//        guard let headerText = self.tableView(tableView, titleForHeaderInSection: section) else {return 0.0}
//        guard headerText != "" else {return 0.0}
//        return 20.0
//    }
//    
//    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
//        guard let header = view as? UITableViewHeaderFooterView else {return}
//        header.textLabel?.font = UIFont.boldSystemFontOfSize(14)
//    }
//    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {}
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
//        guard let downloadTask = self.fetchedResultController.object(at: indexPath) as? DownloadTask,
//            let bookID = downloadTask.book?.id else {return nil}
//        
//        var actions = [UITableViewRowAction]()
//        switch downloadTask.state {
//        case .downloading:
//            let pause = UITableViewRowAction(style: .normal, title: LocalizedStrings.pause) { (action, indexPath) in
//                let operation = PauseBookDwonloadOperation(bookID: bookID)
//                Network.shared.queue.addOperation(operation)
//                tableView.setEditing(false, animated: true)
//            }
//            actions.insert(pause, at: 0)
//        case .paused:
//            let resume = UITableViewRowAction(style: .normal, title: LocalizedStrings.resume) { (action, indexPath) in
//                let operation = ResumeBookDwonloadOperation(bookID: bookID)
//                Network.shared.queue.addOperation(operation)
//                tableView.setEditing(false, animated: true)
//            }
//            actions.insert(resume, at: 0)
//        case .error:
//            let restart = UITableViewRowAction(style: .normal, title: LocalizedStrings.restart) { (action, indexPath) in
//                let operation = ResumeBookDwonloadOperation(bookID: bookID)
//                Network.shared.queue.addOperation(operation)
//                tableView.setEditing(false, animated: true)
//            }
//            actions.insert(restart, at: 0)
//        default:
//            break
//        }
//        
//        let cancel = UITableViewRowAction(style: UITableViewRowActionStyle(), title: LocalizedStrings.cancel) { (action, indexPath) -> Void in
//            if let bookID = downloadTask.book?.id {
//                if let operation = Network.shared.operations[bookID] {
//                    // When download is ongoing
//                    // Cancel the download operation
//                    // URLSessionTaskDelegate will update coredata and do clean up
//                    operation.cancel(produceResumeData: false)
//                } else {
//                    // When download is paused
//                    // Remove resume data
//                    // Delete downloadTask object and set book to not local
//                    downloadTask.book?.removeResumeData()
//                    downloadTask.book?.state = .cloud
//                    self.managedObjectContext.delete(downloadTask)
//                }
//            } else {
//                // In case of something goes wrong, and cannot find the book related to a download task, allow user to delete the row
//                self.managedObjectContext.delete(downloadTask)
//            }
//            tableView.setEditing(false, animated: true)
//        }
//        actions.insert(cancel, at: 0)
//        
//        return actions
        return []
    }
    
    // MARK: - Fetched Results Controller
    
    let managedObjectContext = AppDelegate.persistentContainer.viewContext
    lazy var fetchedResultController: NSFetchedResultsController<DownloadTask> = {
        let fetchRequest = DownloadTask.fetchRequest()
        let creationTimeDescriptor = NSSortDescriptor(key: "creationTime", ascending: true)
        fetchRequest.sortDescriptors = [creationTimeDescriptor]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: "DownloadFRC" + Bundle.buildVersion)
        fetchedResultsController.delegate = self
        fetchedResultsController.performFetch(deleteCache: false)
        return fetchedResultsController as! NSFetchedResultsController<DownloadTask>
    }()
    
}
