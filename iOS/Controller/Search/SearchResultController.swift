//
//  SearchResultController.swift
//  Kiwix
//
//  Created by Chris Li on 11/7/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import ProcedureKit

class SearchResultController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, ProcedureQueueDelegate {
    private let visualView = VisualEffectShadowView()
    private let searchResultView = SearchResultView()
    private let constraints = Constraints()
    private var observer: NSKeyValueObservation?
    
    private let queue = ProcedureQueue()
    private(set) var searchText = ""
    private(set) var results: [SearchResult] = []
    
    let showIcon = true
    
    override func loadView() {
        view = SearchResultControllerBackgroundView()
        searchResultView.tableView.register(SearchResultTitleCell.self, forCellReuseIdentifier: "TitleCell")
        searchResultView.tableView.register(SearchResultTitleSnippetCell.self, forCellReuseIdentifier: "TitleSnippetCell")
        searchResultView.tableView.register(SearchResultTitleIconSnippetCell.self, forCellReuseIdentifier: "TitleIconSnippetCell")
        searchResultView.tableView.dataSource = self
        searchResultView.tableView.delegate = self
        searchResultView.tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        queue.delegate = self
        searchResultView.isHidden = true
        configureSearchResultTableViewInsets()
        observer = view.observe(\.hidden, options: .new, changeHandler: { (view, change) in
            if change.newValue == true { view.isHidden = false }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(notification:)), name: .UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: .UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(notification:)), name: .UIKeyboardDidHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardDidShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardDidHide, object: nil)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass else {return}
        switch traitCollection.horizontalSizeClass {
        case .compact:
            configureForHorizontalCompact()
        case .regular:
            configureForHorizontalRegular()
        case .unspecified:
            break
        }
    }
    
    @objc func keyboardWillShow(notification: Notification)  {
        searchResultView.isHidden = true
    }
    
    @objc func keyboardDidShow(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: NSValue],
            let origin = userInfo[UIKeyboardFrameEndUserInfoKey]?.cgRectValue.origin else {return}
        let point = searchResultView.convert(origin, from: nil)
        searchResultView.bottomInset = searchResultView.frame.height - point.y
        searchResultView.isHidden = false
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        searchResultView.isHidden = true
        searchResultView.bottomInset = 0
    }
    
    @objc func keyboardDidHide(notification: Notification) {
        searchResultView.isHidden = false
    }
    
    private func configureSearchResultTableViewInsets() {
        var separatorInset = searchResultView.tableView.separatorInset
        separatorInset = UIEdgeInsets(top: separatorInset.top, left: separatorInset.left + 38, bottom: separatorInset.bottom, right: separatorInset.right)
        searchResultView.tableView.separatorInset = separatorInset
    }
    
    private func configureForHorizontalCompact() {
        NSLayoutConstraint.deactivate(constraints.regular)
        view.subviews.forEach({ $0.removeFromSuperview() })
        searchResultView.removeFromSuperview()
        view.backgroundColor = .white
        
        searchResultView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchResultView)
        if constraints.compact.count == 0 {
            constraints.compact = {
                if #available(iOS 11.0, *) {
                    return [searchResultView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                            searchResultView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
                            searchResultView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                            searchResultView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor)]
                } else {
                    return [searchResultView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
                            searchResultView.leftAnchor.constraint(equalTo: view.leftAnchor),
                            searchResultView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor),
                            searchResultView.rightAnchor.constraint(equalTo: view.rightAnchor)]
                }
            }()
        }
        
        NSLayoutConstraint.activate(constraints.compact)
    }
    
    private func configureForHorizontalRegular() {
        NSLayoutConstraint.deactivate(constraints.compact)
        view.subviews.forEach({ $0.removeFromSuperview() })
        view.backgroundColor = .clear

        visualView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(visualView)
        searchResultView.translatesAutoresizingMaskIntoConstraints = false
        visualView.contentView.addSubview(searchResultView)
        if constraints.regular.count == 0 {
            var constraints = [visualView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                               visualView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.75),
                               visualView.widthAnchor.constraint(lessThanOrEqualToConstant: 800)]
            let widthConstraint = visualView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.75)
            widthConstraint.priority = .defaultHigh
            constraints.append(widthConstraint)
            
            if #available(iOS 11.0, *) {
                constraints.append(visualView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -visualView.shadow.blur))
            } else {
                constraints.append(visualView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: -visualView.shadow.blur))
            }
            
            constraints += [visualView.contentView.topAnchor.constraint(equalTo: searchResultView.topAnchor),
                            visualView.contentView.leftAnchor.constraint(equalTo: searchResultView.leftAnchor),
                            visualView.contentView.bottomAnchor.constraint(equalTo: searchResultView.bottomAnchor),
                            visualView.contentView.rightAnchor.constraint(equalTo: searchResultView.rightAnchor)]
            
            self.constraints.regular = constraints
        }
        
        NSLayoutConstraint.activate(constraints.regular)
    }
    
    // MARK: -
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let result = results[indexPath.row]
        let identifier: String = {
            switch (showIcon, result.hasSnippet) {
            case (true, _):
                return "TitleIconSnippetCell"
            case (false, true):
                return "TitleSnippetCell"
            case (false, false):
                return "TitleCell"
            }
        }()
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        if let cell = cell as? SearchResultTitleCell {
            cell.title.text = result.title
        } else if let cell = cell as? SearchResultTitleSnippetCell {
            cell.titleLabel.text = result.title
            if let snippet = result.snippet {
                cell.snippetLabel.text = snippet
            } else if let snippet = result.attributedSnippet {
                cell.snippetLabel.attributedText = snippet
            }
        } else if let cell = cell as? SearchResultTitleIconSnippetCell {
            cell.title.text = result.title
            cell.icon.image = UIImage(data: Book.fetch(id: result.zimID, context: CoreDataContainer.shared.viewContext)?.favIcon ?? Data())
            if let snippet = result.snippet {
                cell.snippet.text = snippet
            } else if let snippet = result.attributedSnippet {
                cell.snippet.attributedText = snippet
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let main = presentingViewController as? MainController else {return}
        
        if main.isShowingPanel && main.traitCollection.horizontalSizeClass == .compact { main.hidePanel() }
        main.tabContainerController.load(url: results[indexPath.row].url)
        main.searchController.isActive = false
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if results[indexPath.row].hasSnippet {
            return traitCollection.horizontalSizeClass == .regular ? 120 : 190
        } else {
            return 44
        }
    }
    
    // MARK: - UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else {return}
        let procedure = SearchProcedure(term: searchText)
        procedure.add(condition: MutuallyExclusive<SearchResultController>())
        procedure.add(observer: DidFinishObserver(didFinish: { [unowned self] (procedure, errors) in
            guard let procedure = procedure as? SearchProcedure else {return}
            OperationQueue.main.addOperation({
                self.results = procedure.results
            })
        }))
        queue.add(operation: procedure)
    }
    
    // MARK: - ProcedureQueueDelegate
    
    func procedureQueue(_ queue: ProcedureQueue, willAddProcedure procedure: Procedure, context: Any?) -> ProcedureFuture? {
        if queue.operationCount == 0 {
            DispatchQueue.main.async {
                self.searchResultView.tableView.isHidden = true
                self.searchResultView.emptyResult.isHidden = true
                self.searchResultView.searching.isHidden = false
                self.searchResultView.searching.activityIndicator.startAnimating()
            }
        } else {
            queue.operations.forEach({$0.cancel()})
        }
        return nil
    }
    
    func procedureQueue(_ queue: ProcedureQueue, didFinishProcedure procedure: Procedure, withErrors errors: [Error]) {
        guard queue.operationCount == 0 else {return}
        DispatchQueue.main.async {
            self.searchResultView.searching.activityIndicator.stopAnimating()
            self.searchResultView.searching.isHidden = true
            self.searchResultView.emptyResult.isHidden = self.results.count != 0
            self.searchResultView.tableView.isHidden = self.results.count == 0
            self.searchResultView.tableView.backgroundColor = .clear
            self.searchResultView.tableView.reloadData()
            if self.results.count > 0 {
                let firstRow = IndexPath(row: 0, section: 0)
                self.searchResultView.tableView.scrollToRow(at: firstRow, at: .top, animated: false)
            }
        }
    }
    
    // MARK: -
    
    private class Constraints {
        var regular = [NSLayoutConstraint]()
        var compact = [NSLayoutConstraint]()
    }
    
    private class SearchResultControllerBackgroundView: UIView {
        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            return subviews.map({ $0.frame.contains(point) }).reduce(false, { $0 || $1 })
        }
    }
}

