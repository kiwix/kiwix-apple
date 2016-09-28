//
//  SearchController.swift
//  Kiwix
//
//  Created by Chris Li on 1/30/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import DZNEmptyDataSet

class SearchController: UIViewController, UISearchBarDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var tabControllerContainer: UIView!
    @IBOutlet weak var searchResultTBVCContainer: UIView!
    @IBOutlet var tapGestureRecognizer: UITapGestureRecognizer!
    var searchResultController: SearchResultController?
    
    private var searchTerm = "" // last searchTerm
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tapGestureRecognizer.addTarget(self, action: #selector(SearchController.handleTap(_:)))
        tapGestureRecognizer.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        configureViewVisibility(searchTerm)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "EmbeddedSearchResultController" {
            guard let destinationViewController = segue.destinationViewController as? SearchResultController else {return}
            searchResultController = destinationViewController
        }
    }
    
    func configureViewVisibility(searchTerm: String) {
        if searchTerm == "" {
            searchResultTBVCContainer.hidden = true
            tabControllerContainer.hidden = false
        } else {
            searchResultTBVCContainer.hidden = false
            tabControllerContainer.hidden = true
        }
    }
    
    // MARK: - Search
    
    func startSearch(searchTerm: String, delayed: Bool) {
        guard self.searchTerm != searchTerm else {return}
        self.searchTerm = searchTerm
        configureViewVisibility(searchTerm)
        if delayed {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(275 * USEC_PER_SEC)), dispatch_get_main_queue()) {
                guard searchTerm == self.searchTerm else {return}
                self.searchResultController?.startSearch(self.searchTerm)
            }
        } else {
            searchResultController?.startSearch(searchTerm)
        }
    }
    
    // MARK: - Handle Gesture
    
    func handleTap(tapGestureRecognizer: UIGestureRecognizer) {
        guard let mainVC = parentViewController as? MainController else {return}
        mainVC.hideSearch(animated: true)
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        return touch.view == view ? true : false
    }
}

class SearchTableViewController: UIViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SearchTableViewController.keyboardDidShow(_:)), name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SearchTableViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        tableView.emptyDataSetSource = nil
        tableView.emptyDataSetDelegate = nil
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
    }
    
    func keyboardDidShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo as? [String: NSValue],
            let origin = userInfo[UIKeyboardFrameEndUserInfoKey]?.CGRectValue().origin else {return}
        let point = view.convertPoint(origin, fromView: nil)
        let buttomInset = view.frame.height - point.y
        tableView.contentInset = UIEdgeInsetsMake(0.0, 0, buttomInset, 0)
        tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0.0, 0, buttomInset, 0)
        tableView.reloadEmptyDataSet()
    }
    
    func keyboardWillHide(notification: NSNotification) {
        tableView.contentInset = UIEdgeInsetsMake(0.0, 0, 0, 0)
        tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0.0, 0, 0, 0)
        tableView.reloadEmptyDataSet()
    }
}
