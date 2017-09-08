//
//  SearchResultController.swift
//  WikiMed
//
//  Created by Chris Li on 9/7/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import ProcedureKit

class SearchController: UIViewController, UITableViewDelegate, UITableViewDataSource, ProcedureQueueDelegate {
    let tableView = UITableView()
    let visual = VisualEffectShadowView()
    let background = UIView()
    
    let queue = ProcedureQueue()
    private(set) var results: [SearchResult] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        
        view.backgroundColor = UIColor.clear
        queue.delegate = self
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass else {return}
        view.removeConstraints(visual.constraints)
        if traitCollection.horizontalSizeClass == .regular {
            tableView.removeFromSuperview()
            addBackgroundView()
            addVisualView()
        } else if traitCollection.horizontalSizeClass == .compact {
            background.removeFromSuperview()
            visual.removeFromSuperview()
            addTableView()
        }
    }
    
    private func configureTableView() {
        tableView.register(SearchResultTitleCell.self, forCellReuseIdentifier: "TitleCell")
        tableView.register(SearchResultTitleSnippetCell.self, forCellReuseIdentifier: "TitleSnippetCell")
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    func addTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.removeFromSuperview()
        tableView.backgroundColor = .white
        view.addSubview(tableView)
        view.addConstraints([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
        ])
    }
    
    func addBackgroundView() {
        background.translatesAutoresizingMaskIntoConstraints = false
        background.backgroundColor = UIColor.lightGray.withAlphaComponent(0.25)
        view.addSubview(background)
        if background.gestureRecognizers?.count ?? 0 == 0 {
            background.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(backgroundViewTapped)))
        }
        view.addSubview(background)
        view.addConstraints([
            background.topAnchor.constraint(equalTo: view.topAnchor),
            background.leftAnchor.constraint(equalTo: view.leftAnchor),
            background.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            background.rightAnchor.constraint(equalTo: view.rightAnchor),
        ])
    }
    
    func addVisualView() {
        visual.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(visual)
        let widthPropotion = visual.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.75)
        widthPropotion.priority = .defaultHigh
        view.addConstraints([
            visual.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            visual.topAnchor.constraint(equalTo: view.topAnchor, constant: -visual.shadow.blur),
            visual.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.75),
            widthPropotion,
            visual.widthAnchor.constraint(lessThanOrEqualToConstant: 800)
        ])
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.removeFromSuperview()
        tableView.backgroundColor = .clear
        let contentView = visual.visualEffectView.contentView
        contentView.addSubview(tableView)
        contentView.addConstraints([
            tableView.topAnchor.constraint(equalTo: contentView.topAnchor),
            tableView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            tableView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
        ])
    }
    
    @objc func backgroundViewTapped() {
        guard let main = parent as? MainController else {return}
        main.searchBar.resignFirstResponder()
    }
    
    func startSearch(text: String) {
        let procedure = SearchProcedure(term: text)
        procedure.add(condition: MutuallyExclusive<SearchController>())
        procedure.add(observer: DidFinishObserver(didFinish: { [unowned self] (procedure, errors) in
            guard let procedure = procedure as? SearchProcedure else {return}
            OperationQueue.main.addOperation({
                self.results = procedure.results
            })
        }))
        queue.add(operation: procedure)
    }
    
    // MARK: - UITableView
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let result = results[indexPath.row]
        let identifier = result.hasSnippet ? "TitleSnippetCell" : "TitleCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        
        if let cell = cell as? SearchResultTitleCell {
            cell.titleLabel.text = result.title
        } else if let cell = cell as? SearchResultTitleSnippetCell {
            cell.titleLabel.text = result.title
            if let snippet = result.snippet {
                cell.snippetLabel.text = snippet
            } else if let snippet = result.attributedSnippet {
                cell.snippetLabel.attributedText = snippet
            }
        }
        
        return cell
    }
    
    // MARK: - ProcedureQueueDelegate
    
    func procedureQueue(_ queue: ProcedureQueue, willAddProcedure procedure: Procedure, context: Any?) -> ProcedureFuture? {
        if queue.operationCount == 0 {
            DispatchQueue.main.async {
                //            self.progressIndicator.startAnimation(nil)
                self.tableView.isHidden = true
                //            self.noResultLabel.isHidden = true
            }
        } else {
            queue.operations.forEach({$0.cancel()})
        }
        return nil
    }
    
    func procedureQueue(_ queue: ProcedureQueue, didFinishProcedure procedure: Procedure, withErrors errors: [Error]) {
        guard queue.operationCount == 0 else {return}
        DispatchQueue.main.async {
//            self.progressIndicator.stopAnimation(nil)
            self.tableView.isHidden = self.results.count == 0
//            self.noResultLabel.isHidden = !self.tableView.isHidden
            self.tableView.reloadData()
        }
    }
}
