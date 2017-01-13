//
//  BookmarkArticleController.swift
//  Kiwix
//
//  Created by Chris Li on 1/13/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import CoreData

class BookmarkArticleController: CoreDataTableBaseController, UITableViewDelegate, UITableViewDataSource {
    
    var book: Book? {
        didSet {
            title = book?.title ?? "All"
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    override func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        guard let cell = cell as? BasicBookCell else {return}
        let book = fetchedResultController.object(at: indexPath)
        
        cell.titleLabel.text = book.title
        cell.hasPic = book.hasPic
        cell.favIcon.image = UIImage(data: book.favIcon ?? Data())
        cell.subtitleLabel.text = book.detailedDescription
        cell.accessoryType = splitViewController?.traitCollection.horizontalSizeClass == .compact ? .disclosureIndicator : .none
    }

}
