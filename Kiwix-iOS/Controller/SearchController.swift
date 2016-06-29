//
//  SearchController.swift
//  Kiwix
//
//  Created by Chris Li on 1/30/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class SearchController: UIViewController, UISearchBarDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var tabControllerContainer: UIView!
    @IBOutlet weak var searchResultTBVCContainer: UIView!
    @IBOutlet var tapGestureRecognizer: UITapGestureRecognizer!
    var searchResultTBVC: SearchResultTBVC?
    
    var searchText = "" {
        didSet {
            configureViewVisibility()
            searchResultTBVC?.startSearch(searchText)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tapGestureRecognizer.addTarget(self, action: #selector(SearchController.handleTap(_:)))
        tapGestureRecognizer.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        configureViewVisibility()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        guard searchText != "" else {return}
        Preference.recentSearchTerms.insert(searchText, atIndex: 0)
        searchText = ""
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "EmbeddedSearchResultTBVC" {
            guard let destinationViewController = segue.destinationViewController as? SearchResultTBVC else {return}
            searchResultTBVC = destinationViewController
        }
    }
    
    func configureViewVisibility() {
        if searchText == "" {
            searchResultTBVCContainer.hidden = true
            tabControllerContainer.hidden = false
        } else {
            searchResultTBVCContainer.hidden = false
            tabControllerContainer.hidden = true
        }
    }
    
    // MARK: - Handle Gesture
    
    func handleTap(tapGestureRecognizer: UIGestureRecognizer) {
        guard let mainVC = parentViewController as? MainVC else {return}
        mainVC.hideSearch()
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        return touch.view == view ? true : false
    }
    
}
