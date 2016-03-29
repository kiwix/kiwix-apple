//
//  SearchResultTBVC.swift
//  Kiwix
//
//  Created by Chris Li on 8/13/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit

class SearchResultTBVC: UIViewController, UITableViewDataSource, UITableViewDelegate, SortOperationDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    var searchResults = [(id: String, articleTitle: String)]()
    
    var shouldClipRoundCorner: Bool {
        return traitCollection.verticalSizeClass == .Regular && traitCollection.horizontalSizeClass == .Regular
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        tableView.contentInset = UIEdgeInsetsMake(0.0, 0, 0, 0)
        tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0.0, 0, 0, 0)
        tableView.layer.cornerRadius = shouldClipRoundCorner ? 10.0 : 0.0
        tableView.layer.masksToBounds = shouldClipRoundCorner
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardDidShow:", name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
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
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        guard let mainVC = parentViewController?.parentViewController as? MainVC else {return}
        let result = searchResults[indexPath.row]
        let url = NSURL.kiwixURLWithZimFileid(result.id, articleTitle: result.articleTitle)
        mainVC.load(url)
        mainVC.hideSearch()
    }

    // MARK: - Search Result Updater
    
    func startSearch(searchText: String) {
        UIApplication.searchEngine.searchQueue.cancelAllOperations()
        UIApplication.searchEngine.searchInProgress.removeAll()
        searchResults.removeAll()
        
        guard searchText != "" else {tableView.reloadData(); return}
        
        let sortOperation = SortOperation()
        let sortOperationIdentifier = searchText + "_Sort"
        sortOperation.delegate = self
        sortOperation.completionBlock = {
            UIApplication.searchEngine.searchInProgress.removeAll()
        }
        UIApplication.searchEngine.searchInProgress[sortOperationIdentifier] = sortOperation
        
        let zimFileIDs = Array(UIApplication.multiReader.readers.keys)
        for id in zimFileIDs {
            let identifier = searchText + "_" + id
            let searchOperation = SearchOperation(searchTerm: searchText, zimFileID: id)
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
            self.tableView.setContentOffset(CGPointMake(0, 0 - self.tableView.contentInset.top), animated: true)
        }
    }
}

extension LocalizedStrings {
    class var searchAddBookGuide: String {return NSLocalizedString("Add a book to get started", comment: "")}
}
