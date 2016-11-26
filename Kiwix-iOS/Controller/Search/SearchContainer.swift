//
//  SearchContainer.swift
//  Kiwix
//
//  Created by Chris Li on 11/14/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit
import ProcedureKit

class SearchContainer: UIViewController {
    
    @IBOutlet weak var dimView: UIView!
    @IBOutlet weak var scopeAndHistoryContainer: UIView!
    @IBOutlet weak var resultContainer: UIView!
    private var resultController: SearchResultController!
    var delegate: SearchContainerDelegate?
    
    @IBAction func handleDimViewTap(_ sender: UITapGestureRecognizer) {
        delegate?.didTapSearchDimView()
    }
    
    // MARK: - Overrides

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //EmbeddedScopeAndHistoryController
        
        if segue.identifier == "" {
            
        } else if segue.identifier == "EmbeddedResultController" {
            resultController = segue.destination as! SearchResultController
        }
    }
    
    // MARK: - Search
    
    var searchText = "" {
        didSet {
            configureVisibility()
            startSearch()
        }
    }
    
    private func configureVisibility() {
        let shouldHideResults = searchText == ""
        scopeAndHistoryContainer.isHidden = !shouldHideResults
        resultContainer.isHidden = shouldHideResults
    }
    
    private func startSearch() {
        let search = SearchOperation(searchText: searchText)
        GlobalQueue.shared.add(operation: search)
        search.add(observer: DidFinishObserver { [unowned self] (operation, errors) in
            guard let search = operation as? SearchOperation else {return}
            OperationQueue.main.addOperation({ 
                self.resultController.reload(searchText: self.searchText, results: search.results)
            })
        })
    }
}

protocol SearchContainerDelegate: class {
    func didTapSearchDimView()
}
