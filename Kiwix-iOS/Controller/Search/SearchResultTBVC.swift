//
//  SearchResultTBVC.swift
//  Kiwix
//
//  Created by Chris Li on 8/13/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit
import Operations

class SearchResultTBVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    var searchResults = [SearchResult]()
    
    var shouldClipRoundCorner: Bool {
        return traitCollection.verticalSizeClass == .Regular && traitCollection.horizontalSizeClass == .Regular
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.keyboardDismissMode = .OnDrag
    }
    
    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        tableView.contentInset = UIEdgeInsetsMake(0.0, 0, 0, 0)
        tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0.0, 0, 0, 0)
        tableView.layer.cornerRadius = shouldClipRoundCorner ? 10.0 : 0.0
        tableView.layer.masksToBounds = shouldClipRoundCorner
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SearchResultTBVC.keyboardDidShow(_:)), name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SearchResultTBVC.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        searchResults.removeAll()
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardDidShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo as? [String: NSValue] else {return}
        guard let keyboardOrigin = userInfo[UIKeyboardFrameEndUserInfoKey]?.CGRectValue().origin else {return}
        let point = view.convertPoint(keyboardOrigin, fromView: UIApplication.appDelegate.window)
        let buttomInset = view.frame.height - point.y
        tableView.contentInset = UIEdgeInsetsMake(0.0, 0, buttomInset, 0)
        tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0.0, 0, buttomInset, 0)
    }
    
    func keyboardWillHide(notification: NSNotification) {
        tableView.contentInset = UIEdgeInsetsMake(0.0, 0, 0, 0)
        tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0.0, 0, 0, 0)
    }
    
    func selectFirstResultIfPossible() {
        guard searchResults.count > 0 else {return}
        tableView.selectRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), animated: true, scrollPosition: .Top)
        tableView(tableView, didSelectRowAtIndexPath: NSIndexPath(forRow: 0, inSection: 0))
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
        guard let mainVC = parentViewController?.parentViewController as? MainController else {return}
        let result = searchResults[indexPath.row]
        let url = NSURL.kiwixURLWithZimFileid(result.bookID, articleTitle: result.title)
        mainVC.load(url)
        mainVC.hideSearch(animated: true)
    }

    // MARK: - Search
    
    func startSearch(searchText: String) {
        guard searchText != "" else {
            searchResults.removeAll()
            tableView.reloadData()
            return
        }
//        let operation = SearchOperation(searchTerm: searchText) { [unowned self] (results) in
//            guard let results = results else {return}
//            self.searchResults = results
//            self.tableView.reloadData()
//            if results.count > 0 {
//                self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: .Top, animated: true)
//            }
//        }
        let operation = SearchOperation(searchTerm: searchText)
        operation.addObserver(DidFinishObserver {(operation, errors) in
            print("search op did finish, result injection")
        })
        GlobalQueue.shared.add(search: operation)
    }
}

extension LocalizedStrings {
    class var searchAddBookGuide: String {return NSLocalizedString("Add a book to get started", comment: "")}
}
