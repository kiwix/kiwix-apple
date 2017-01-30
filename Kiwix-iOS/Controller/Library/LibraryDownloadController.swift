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
    
    let progressFormatter = Progress()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Localized.Library.download
        progressFormatter.kind = .file
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
        configureCell(cell, atIndexPath: indexPath, animated: false)
        return cell
    }
    
    override func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath, animated: Bool = false) {
        guard let cell = cell as? DownloadTaskCell else {return}
        
        let downloadTask = fetchedResultController.object(at: indexPath)
        guard let book = downloadTask.book else {return}
        
        progressFormatter.completedUnitCount = downloadTask.totalBytesWritten
        progressFormatter.totalUnitCount = book.fileSize
        
        if let data = book.favIcon {cell.thumbImageView.image = UIImage(data: data)}
        cell.titleLabel.text = book.title
        cell.subtitleLabel.text = progressFormatter.localizedAdditionalDescription
        cell.progressView.setProgress(Float(downloadTask.totalBytesWritten) / Float(book.fileSize), animated: animated)
    }
    
    // MARK: - Table view delegate
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let downloadTask = fetchedResultController.object(at: indexPath)
        guard let book = downloadTask.book else {return []}
        let cancel = UITableViewRowAction(style: .destructive, title: Localized.Common.cancel) { (action, indexPath) in
            Network.shared.cancel(bookID: book.id)
        }
        return [cancel]
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
