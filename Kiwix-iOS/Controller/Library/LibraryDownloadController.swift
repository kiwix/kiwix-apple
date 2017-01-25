//
//  LibraryDownloadController.swift
//  Kiwix
//
//  Created by Chris Li on 1/25/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import CoreData

class LibraryDownloadController: CoreDataTableBaseController, UITableViewDelegate, UITableViewDataSource {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func dismissButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultController.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultController.sections?[section].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    override func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        let downloadTask = fetchedResultController.object(at: indexPath)
        let book = downloadTask.book
        cell.textLabel?.text = book?.title
        cell.detailTextLabel?.text = "\(downloadTask.totalBytesWritten)"
    }

    // MARK: - NSFetchedResultsController
    
    let managedObjectContext = AppDelegate.persistentContainer.viewContext
    lazy var fetchedResultController: NSFetchedResultsController<DownloadTask> = {
        let fetchRequest = DownloadTask.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationTime", ascending: false)]
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                    managedObjectContext: self.managedObjectContext,
                                                    sectionNameKeyPath: "stateRaw", cacheName: nil)
        controller.delegate = self
        try? controller.performFetch()
        return controller as! NSFetchedResultsController<DownloadTask>
    }()
}
