//
//  SearchOperationQueue.swift
//  Kiwix
//
//  Created by Chris on 9/20/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit

class SearchOperation: NSOperation {
    let searchTerm: String
    let zimFileID: String
    var results = [(id: String, articleTitle: String)]()
    
    init(searchTerm: String, zimFileID: String) {
        self.searchTerm = searchTerm
        self.zimFileID = zimFileID
    }
    
    override func main() {
        if cancelled {return}
        results = UIApplication.multiReader.search(searchTerm, zimFileID: zimFileID)
    }
}

class SortOperation: NSOperation {
    var results = [(id: String, articleTitle: String)]()
    var delegate: SortOperationDelegate?
    var searchOperationCount = 0
    
    override func main() {
        for operation in dependencies {
            guard let operation = operation as? SearchOperation else {continue}
            searchOperationCount++
            results += operation.results
        }
        
        if searchOperationCount > 1 {
            results.sortInPlace { (item1, item2) -> Bool in
                let articleTitle1 = item1.articleTitle
                let articleTitle2 = item2.articleTitle
                return articleTitle1.caseInsensitiveCompare(articleTitle2) == .OrderedAscending
            }
        }
        
        self.delegate?.sortFinishedWithResults(results)
    }
}

class SearchEngine  {
    lazy var searchInProgress = [String : NSOperation]()
    lazy var searchQueue: NSOperationQueue = {
        var queue = NSOperationQueue()
        queue.qualityOfService = .UserInitiated
        queue.maxConcurrentOperationCount = 4
        return queue
    }()
}

protocol SortOperationDelegate {
    func sortFinishedWithResults(results: [(id: String, articleTitle: String)])
}