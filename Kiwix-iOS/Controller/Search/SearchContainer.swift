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
    
    var searchText = "" {
        didSet {
            configureVisibility()
            startSearch()
        }
    }

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
    
    @IBAction func handleDimViewTap(_ sender: UITapGestureRecognizer) {
        delegate?.didTapDimView()
    }
}

protocol SearchContainerDelegate: class {
    func didTapDimView()
}
