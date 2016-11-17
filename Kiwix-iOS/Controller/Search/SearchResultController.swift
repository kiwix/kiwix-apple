//
//  SearchResultController.swift
//  Kiwix
//
//  Created by Chris Li on 8/13/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit
import ProcedureKit
import DZNEmptyDataSet

class SearchResultController: SearchBaseTableController, UITableViewDataSource, UITableViewDelegate {
    
    private var searchResults = [SearchResult]()
    private var shouldShowNoResults = false
    
    // MARK: - Override
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.keyboardDismissMode = .onDrag
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
    }
    
    // MARK: -
    
    func selectFirstResultIfPossible() {
        guard searchResults.count > 0 else {return}
        tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: .top)
        tableView(tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
    }
    
    func reload(searchText: String, results: [SearchResult]) {
        shouldShowNoResults = searchText != ""
        searchResults = results
        
        tableView.tableFooterView = searchResults.count > 0 ? nil : UIView()
        tableView.reloadData()
        tableView.reloadEmptyDataSet()
        
        guard searchResults.count > 0 else {return}
        self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }
    
    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let result = searchResults[indexPath.row]
        
        if result.snippet == nil {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ArticleCell", for: indexPath) as! ArticleCell
            configureArticleCell(cell, result: result)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ArticleSnippetCell", for: indexPath) as! ArticleSnippetCell
            configureArticleCell(cell, result: result)
            cell.snippetLabel.text = result.snippet
            return cell
        }
    }
    
    func configureArticleCell(_ cell: ArticleCell, result: SearchResult) {
        guard let book = Book.fetch(result.bookID, context: AppDelegate.persistentContainer.viewContext) else {return}
        if UIApplication.buildStatus == .alpha {
            cell.titleLabel.text = result.title + result.rankInfo
        } else {
            cell.titleLabel.text = result.title
        }
        cell.hasPicIndicator.backgroundColor = book.hasPic ? AppColors.hasPicTintColor : UIColor.lightGray
        cell.favIcon.image = book.favIcon != nil ? UIImage(data: book.favIcon!) : nil
    }
    
    // MARK: Table view delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let result = searchResults[indexPath.row]
        let operation = ArticleLoadOperation(bookID: result.bookID, articlePath: result.path)
        GlobalQueue.shared.add(articleLoadOperation: operation)
    }

    // MARK: - DZNEmptyDataSet
    
    func titleForEmptyDataSet(_ scrollView: UIScrollView!) -> NSAttributedString! {
        guard shouldShowNoResults else {return nil}
        let string = NSLocalizedString("No Results", comment: "Search, Results")
        let attributes = [NSFontAttributeName: UIFont.systemFont(ofSize: 18), NSForegroundColorAttributeName: UIColor.darkGray]
        return NSAttributedString(string: string, attributes: attributes)
    }
    
    func descriptionForEmptyDataSet(_ scrollView: UIScrollView!) -> NSAttributedString! {
        guard shouldShowNoResults else {return nil}
        let string = NSLocalizedString("Please refine your search term.", comment: "Search, Results")
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.alignment = .center
        let attributes = [NSFontAttributeName: UIFont.systemFont(ofSize: 14), NSForegroundColorAttributeName: UIColor.lightGray, NSParagraphStyleAttributeName: paragraph]
        return NSAttributedString(string: string, attributes: attributes)
    }
    
    func verticalOffsetForEmptyDataSet(_ scrollView: UIScrollView!) -> CGFloat {
        return -tableView.contentInset.bottom / 2.5
    }
}
