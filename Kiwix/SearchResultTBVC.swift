//
//  SearchResultTBVC.swift
//  Kiwix
//
//  Created by Chris Li on 8/13/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit

class SearchResultTBVC: UITableViewController, UISearchResultsUpdating, SortOperationDelegate {
    
    var searchResults = [(id: String, articleTitle: String)]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    // This commended out part is for showing add book message when user have no book 
//    override func viewWillAppear(animated: Bool) {
//        super.viewWillAppear(animated)
//        if UIApplication.multiReader.readers.count == 0 {
//            tableView.setBackgroundText(LocalizedStrings.searchAddBookGuide)
//            tableView.tableFooterView = UIView()
//        } else {
//            tableView.tableFooterView = nil
//        }
//    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ArticleCell", forIndexPath: indexPath) as! ArticleCell
        
        let result = searchResults[indexPath.row]
        guard let book = Book.fetch(result.id, context: UIApplication.appDelegate.managedObjectContext) else {return cell}
        let articleTitle = result.articleTitle
        
        cell.titleLabel.text = articleTitle
        cell.hasPicIndicator.backgroundColor = book.isNoPic!.boolValue ? UIColor.lightGrayColor() : UIColor.havePicTintColor
        cell.favIcon.image = book.favIcon != nil ? UIImage(data: book.favIcon!) : nil
        
        return cell
    }
    
    // MARK: Table view delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let navigationController = self.presentingViewController as? UINavigationController else {return}
        guard let mainVC = navigationController.topViewController as? MainVC else {return}
        let result = searchResults[indexPath.row]
        let url = NSURL.kiwixURLWithZimFileid(result.id, articleTitle: result.articleTitle)
        mainVC.load(url)
        mainVC.searchController.active = false
    }

    // MARK: - UISearchResultUpdating
    
    var results = [[(id: String, articleTitle: String)]]()
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        UIApplication.searchEngine.searchQueue.cancelAllOperations()
        UIApplication.searchEngine.searchInProgress.removeAll()
        searchResults.removeAll()
        
        guard let searchTerm = searchController.searchBar.text else {return}
        guard searchTerm != "" else {tableView.reloadData(); return}
        
        let sortOperation = SortOperation()
        let sortOperationIdentifier = searchTerm + "_Sort"
        sortOperation.delegate = self
        sortOperation.completionBlock = {
            UIApplication.searchEngine.searchInProgress.removeAll()
        }
        UIApplication.searchEngine.searchInProgress[sortOperationIdentifier] = sortOperation
        
        let zimFileIDs = Array(UIApplication.multiReader.readers.keys)
        for id in zimFileIDs {
            let identifier = searchTerm + "_" + id
            let searchOperation = SearchOperation(searchTerm: searchTerm, zimFileID: id)
            sortOperation.addDependency(searchOperation)
            UIApplication.searchEngine.searchInProgress[identifier] = searchOperation
            UIApplication.searchEngine.searchQueue.addOperation(searchOperation)
        }
        
        UIApplication.searchEngine.searchQueue.addOperation(sortOperation)
    }
    
    // MARK: - SortOperationDelegate
    
    func sortFinishedWithResults(results: [(id: String, articleTitle: String)]) {
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            self.searchResults = results
            self.tableView.reloadData()
        }
    }
}

extension LocalizedStrings {
    class var searchAddBookGuide: String {return NSLocalizedString("Add a book to get started", comment: "")}
}
