//
//  SearchBooksController.swift
//  Kiwix
//
//  Created by Chris Li on 4/7/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit
import CoreData
import DZNEmptyDataSet

class SearchScopeAndHistoryController: SearchBaseTableController, UITableViewDelegate, UITableViewDataSource, TableCellDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

    @IBOutlet weak var recentSearchContainer: DropShadowView!
    @IBOutlet weak var recentSearchBarHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.keyboardDismissMode = .onDrag
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        configureRecentSearchBarHeight()
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
    }
    
    func configureRecentSearchBarHeight() {
        let newHeight: CGFloat = Preference.RecentSearch.terms.count == 0 ? 0.0 : 44.0
        guard recentSearchBarHeight.constant != newHeight else {return}
        recentSearchBarHeight.constant = newHeight
        recentSearchContainer.setNeedsDisplay()
    }
    
    // MARK: - Table Cell Delegate
    
    func didTapCheckMark(cell: UITableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else {return}
        let book = fetchedResultController.object(at: indexPath)
        managedObjectContext.performAndWait { 
            book.includeInSearch = !book.includeInSearch
        }
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultController.sections?.count ?? 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionInfo = fetchedResultController.sections?[section] else {return 0}
        return sectionInfo.numberOfObjects
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CheckMarkBookCell", for: indexPath)
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    override func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        guard let cell = cell as? CheckMarkBookCell else {return}
        let book = fetchedResultController.object(at: indexPath)
        
        cell.delegate = self
        cell.titleLabel.text = book.title
        cell.subtitleLabel.text = book.detailedDescription

        cell.favIcon.image = UIImage(data: book.favIcon ?? Data())
        cell.hasPic = book.hasPic
        cell.isChecked = book.includeInSearch
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard tableView.numberOfSections > 1 else {return nil}
        guard let languageName = fetchedResultController.sections?[section].name else {return nil}
        return languageName
    }
    
    // MARK: Table view delegate
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let headerText = self.tableView(tableView, titleForHeaderInSection: section) else {return 0.0}
        guard headerText != "" else {return 0.0}
        return 20.0
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else {return}
        header.textLabel?.font = UIFont.boldSystemFont(ofSize: 14)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let book = fetchedResultController.object(at: indexPath)
        let operation = ArticleLoadOperation(bookID: book.id)
        GlobalQueue.shared.add(articleLoadOperation: operation)
    }
    
    // MARK: - DZNEmptyDataSet
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let string = NSLocalizedString("No Books Available", comment: "Search, Book Selector")
        let attributes = [NSFontAttributeName: UIFont.systemFont(ofSize: 18), NSForegroundColorAttributeName: UIColor.darkGray]
        return NSAttributedString(string: string, attributes: attributes)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let string = NSLocalizedString("Please download or import a book.", comment: "Search, Book Selector")
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.alignment = .center
        let attributes = [NSFontAttributeName: UIFont.systemFont(ofSize: 14), NSForegroundColorAttributeName: UIColor.lightGray, NSParagraphStyleAttributeName: paragraph]
        return NSAttributedString(string: string, attributes: attributes)
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return -(tableView.contentInset.bottom + recentSearchBarHeight.constant) / 2.5
    }
    
    // MARK: - Fetched Results Controller
    
    let managedObjectContext = AppDelegate.persistentContainer.viewContext
    lazy var fetchedResultController: NSFetchedResultsController<Book> = {
        let fetchRequest = Book.fetchRequest()
        let langDescriptor = NSSortDescriptor(key: "language.name", ascending: true)
        let titleDescriptor = NSSortDescriptor(key: "title", ascending: true)
        fetchRequest.sortDescriptors = [langDescriptor, titleDescriptor]
        fetchRequest.predicate = NSPredicate(format: "stateRaw == 2")
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: "ScopeFRC" + Bundle.buildVersion)
        fetchedResultsController.delegate = self
        try? fetchedResultsController.performFetch()
        return fetchedResultsController as! NSFetchedResultsController<Book>
    }()
}
