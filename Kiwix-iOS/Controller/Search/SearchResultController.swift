//
//  SearchResultController.swift
//  Kiwix
//
//  Created by Chris Li on 8/13/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit
import Operations
import DZNEmptyDataSet

class SearchResultController: SearchTableViewController, UITableViewDataSource, UITableViewDelegate {
    
    var searchResults = [SearchResult]()
    
    var shouldShowNoResults = false
    var shouldClipRoundCorner: Bool {
        return traitCollection.verticalSizeClass == .Regular && traitCollection.horizontalSizeClass == .Regular
    }
    
    // MARK: - Override
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.keyboardDismissMode = .OnDrag
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
    }
    
    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        guard traitCollection != previousTraitCollection else {return}
        tableView.layer.cornerRadius = shouldClipRoundCorner ? 10.0 : 0.0
        tableView.layer.masksToBounds = shouldClipRoundCorner
    }
    
    // MARK: -
    
    func selectFirstResultIfPossible() {
        guard searchResults.count > 0 else {return}
        tableView.selectRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), animated: true, scrollPosition: .Top)
        tableView(tableView, didSelectRowAtIndexPath: NSIndexPath(forRow: 0, inSection: 0))
    }
    
    func reload(results results: [SearchResult]?) {
        if let results = results {
            searchResults = results
        } else {
            searchResults.removeAll()
        }
        
        tableView.tableFooterView = searchResults.count > 0 ? nil : UIView()
        tableView.reloadData()
        tableView.reloadEmptyDataSet()
        
        guard searchResults.count > 0 else {return}
        self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: .Top, animated: true)
    }
    
    func startSearch(searchText: String) {
        guard searchText != "" else {
            shouldShowNoResults = false
            reload(results: nil)
            return
        }
        
        let operation = SearchOperation(searchTerm: searchText)
        operation.addObserver(DidFinishObserver {(operation, errors) in
            guard let operation = operation as? SearchOperation else {return}
            NSOperationQueue.mainQueue().addOperationWithBlock({
                self.shouldShowNoResults = true
                self.reload(results: operation.results)
            })
        })
        GlobalQueue.shared.add(search: operation)
        shouldShowNoResults = false
    }
    
    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let result = searchResults[indexPath.row]
        
        if result.snippet == nil {
            let cell = tableView.dequeueReusableCellWithIdentifier("ArticleCell", forIndexPath: indexPath) as! ArticleCell
            configureArticleCell(cell, result: result)
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("ArticleSnippetCell", forIndexPath: indexPath) as! ArticleSnippetCell
            configureArticleCell(cell, result: result)
            cell.snippetLabel.text = result.snippet
            return cell
        }
    }
    
    func configureArticleCell(cell: ArticleCell, result: SearchResult) {
        guard let book = Book.fetch(result.bookID, context: UIApplication.appDelegate.managedObjectContext) else {return}
        if UIApplication.buildStatus == .Alpha {
            cell.titleLabel.text = result.title + result.rankInfo
        } else {
            cell.titleLabel.text = result.title
        }
        cell.hasPicIndicator.backgroundColor = book.hasPic ? AppColors.hasPicTintColor : UIColor.lightGrayColor()
        cell.favIcon.image = book.favIcon != nil ? UIImage(data: book.favIcon!) : nil
    }
    
    // MARK: Table view delegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if let searchTerm = Controllers.main.searchBar.searchTerm {
            Preference.RecentSearch.add(term: searchTerm)
        }
        
        let result = searchResults[indexPath.row]
        let operation = ArticleLoadOperation(bookID: result.bookID, articleTitle: result.title)
        GlobalQueue.shared.add(load: operation)
    }

    // MARK: - DZNEmptyDataSet
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        guard shouldShowNoResults else {return nil}
        let string = NSLocalizedString("No Results", comment: "Search, Results")
        let attributes = [NSFontAttributeName: UIFont.systemFontOfSize(18), NSForegroundColorAttributeName: UIColor.darkGrayColor()]
        return NSAttributedString(string: string, attributes: attributes)
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        guard shouldShowNoResults else {return nil}
        let string = NSLocalizedString("Please refine your search term.", comment: "Search, Results")
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .ByWordWrapping
        paragraph.alignment = .Center
        let attributes = [NSFontAttributeName: UIFont.systemFontOfSize(14), NSForegroundColorAttributeName: UIColor.lightGrayColor(), NSParagraphStyleAttributeName: paragraph]
        return NSAttributedString(string: string, attributes: attributes)
    }
    
    func verticalOffsetForEmptyDataSet(scrollView: UIScrollView!) -> CGFloat {
        return -tableView.contentInset.bottom / 2.5
    }
}
