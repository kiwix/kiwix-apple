//
//  SearchResultTBVC.swift
//  Kiwix
//
//  Created by Chris Li on 8/13/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit

class SearchResultTBVC: UITableViewController, UISearchResultsUpdating {
    
    var searchResults = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ArticleCell", forIndexPath: indexPath) as! ArticleCell
        
        var components = searchResults[indexPath.row].componentsSeparatedByString("/")
        let book: Book? = {
            if let idString = components.first {
                return ZimMultiReader.sharedInstance.allLocalBooksInDataBase[idString]
            } else {
                return nil
            }
        }()
        components.removeFirst()
        let articleTitle = components.joinWithSeparator("/")
        
        cell.titleLabel.text = articleTitle
        if let book = book {
            cell.hasPicIndicator.backgroundColor = book.isNoPic!.boolValue ? UIColor.lightGrayColor() : Utilities.customTintColor()
            cell.favIcon.image = book.favIcon != nil ? UIImage(data: book.favIcon!) : nil
        }
        
        return cell
    }
    
    // MARK: Table view delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let navigationController = self.presentingViewController as? UINavigationController, let mainViewController = navigationController.topViewController as? MainViewController {
            mainViewController.load(articlePath: searchResults[indexPath.row])
            mainViewController.searchController.active = false
        }
    }

    // MARK: - UISearchResultUpdating
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        if let searchTerm = searchController.searchBar.text {
            searchResults = ZimMultiReader.sharedInstance.searchInAllZimFiles(searchTerm)
        } else {
            searchResults = [String]()
        }
        tableView.reloadData()
    }
}
