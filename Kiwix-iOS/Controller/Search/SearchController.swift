//
//  SearchController.swift
//  Kiwix
//
//  Created by Chris Li on 1/30/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit
import DZNEmptyDataSet

class SearchController: UIViewController, UISearchBarDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var tabControllerContainer: UIView!
    @IBOutlet weak var searchResultTBVCContainer: UIView!
    @IBOutlet var tapGestureRecognizer: UITapGestureRecognizer!
    var searchResultController: SearchResultController?
    
    fileprivate var searchTerm = "" // last searchTerm
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tapGestureRecognizer.addTarget(self, action: #selector(SearchController.handleTap(_:)))
        tapGestureRecognizer.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureViewVisibility(searchTerm)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EmbeddedSearchResultController" {
            guard let destinationViewController = segue.destination as? SearchResultController else {return}
            searchResultController = destinationViewController
        }
    }
    
    func configureViewVisibility(_ searchTerm: String) {
        if searchTerm == "" {
            searchResultTBVCContainer.isHidden = true
            tabControllerContainer.isHidden = false
        } else {
            searchResultTBVCContainer.isHidden = false
            tabControllerContainer.isHidden = true
        }
    }
    
    // MARK: - Search
    
    func startSearch(_ searchTerm: String, delayed: Bool) {
        guard self.searchTerm != searchTerm else {return}
        self.searchTerm = searchTerm
        configureViewVisibility(searchTerm)
        if delayed {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(275 * USEC_PER_SEC)) / Double(NSEC_PER_SEC)) {
                guard searchTerm == self.searchTerm else {return}
                self.searchResultController?.startSearch(self.searchTerm)
            }
        } else {
            searchResultController?.startSearch(searchTerm)
        }
    }
    
    // MARK: - Handle Gesture
    
    func handleTap(_ tapGestureRecognizer: UIGestureRecognizer) {
        guard let mainVC = parent as? MainController else {return}
//        mainVC.hideSearch(animated: true)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == view ? true : false
    }
}


