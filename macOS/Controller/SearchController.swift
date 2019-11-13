//
//  Search.swift
//  macOS
//
//  Created by Chris Li on 11/11/19.
//  Copyright © 2019 Chris Li. All rights reserved.
//

import Cocoa

class SearchWindow: NSWindow {
    override var canBecomeKey: Bool {
        return false
    }
}


class SearchController: NSViewController, SearchQueueEvents {
    @IBOutlet weak var tabView: NSTabView!
    @IBOutlet weak var resultsOutlineView: NSOutlineView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    private let queue = SearchQueue()
    private(set) var searchText: String = ""
    private var results = [SearchResult]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        queue.eventDelegate = self
    }
    
    func startSearch(searchText: String) {
        let zimFileIDs: Set<String> = Set(ZimMultiReader.shared.ids)
        queue.enqueue(searchText: searchText, zimFileIDs: zimFileIDs)
    }
    
    // MARK: SearchQueueEvents
    
    func searchStarted() {
        tabView.selectTabViewItem(withIdentifier: Mode.inProgress.rawValue)
        progressIndicator.startAnimation(nil)
    }
    
    func searchFinished(searchText: String, results: [SearchResult]) {
        self.searchText = searchText
        self.results = results
        resultsOutlineView.reloadData()
        progressIndicator.stopAnimation(nil)
        if results.count > 0 {
            tabView.selectTabViewItem(withIdentifier: Mode.results.rawValue)
        } else {
            tabView.selectTabViewItem(withIdentifier: Mode.noResult.rawValue)
        }
    }
}

private enum Mode: String {
    case results = "Results"
    case inProgress = "InProgress"
    case noResult = "NoResult"
}
