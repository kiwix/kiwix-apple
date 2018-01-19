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
    private let searchResultContainer = SearchResultContainerView()
    private let tableView = UITableView()
    private let emptyResultView = SearchEmptyResultView()
    private let searchingView = SearchingView()
    private let searchNoTextController = SearchNoTextController()
    
    private var regularConstraints = [NSLayoutConstraint]()
    private var compactConstraints = [NSLayoutConstraint]()
    
    private var observer: NSKeyValueObservation?
    
    private let queue = ProcedureQueue()
    private(set) var searchText = ""
    private(set) var results: [SearchResult] = []
    
    // MARK: - Overrides
    
    override func loadView() {
        view = SearchResultControllerBackgroundView()
        tableView.register(ArticleTableCell.self, forCellReuseIdentifier: "Cell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .onDrag
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        queue.delegate = self
        searchResultContainer.isHidden = true
        addChildViewController(searchNoTextController)
        searchResultContainer.setContent(view: searchNoTextController.view)
        searchNoTextController.didMove(toParentViewController: self)
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
        if !searchResultContainer.subviews.contains(tableView) {
            searchResultContainer.isHidden = true
        }
    }
    
    @objc func keyboardDidShow(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: NSValue],
            let origin = userInfo[UIKeyboardFrameEndUserInfoKey]?.cgRectValue.origin else {return}
        let point = searchResultContainer.convert(origin, from: nil)
        searchResultContainer.bottomInset = searchResultContainer.frame.height - point.y
        searchResultContainer.isHidden = false
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        if !searchResultContainer.subviews.contains(tableView) {
            searchResultContainer.isHidden = true
        }
        searchResultContainer.bottomInset = 0
    }
    
    @objc func keyboardDidHide(notification: Notification) {
        searchResultContainer.isHidden = false
    }
    
    private func configureForHorizontalCompact() {
        NSLayoutConstraint.deactivate(regularConstraints)
        view.subviews.forEach({ $0.removeFromSuperview() })
        searchResultContainer.removeFromSuperview()
        view.backgroundColor = .white
        
        searchResultContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchResultContainer)
        if compactConstraints.count == 0 {
            if #available(iOS 11.0, *) {
                compactConstraints += [
                    searchResultContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                    searchResultContainer.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
                    searchResultContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                    searchResultContainer.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor)]
            } else {
                compactConstraints += [
                    searchResultContainer.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
                    searchResultContainer.leftAnchor.constraint(equalTo: view.leftAnchor),
                    searchResultContainer.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor),
                    searchResultContainer.rightAnchor.constraint(equalTo: view.rightAnchor)]
            }
        }
        
        NSLayoutConstraint.activate(compactConstraints)
    }
    
    private func configureForHorizontalRegular() {
        NSLayoutConstraint.deactivate(compactConstraints)
        view.subviews.forEach({ $0.removeFromSuperview() })
        view.backgroundColor = .clear

        visualView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(visualView)
        searchResultContainer.translatesAutoresizingMaskIntoConstraints = false
        visualView.contentView.addSubview(searchResultContainer)
        if regularConstraints.count == 0 {
            regularConstraints += [
                visualView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                visualView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.75),
                visualView.widthAnchor.constraint(lessThanOrEqualToConstant: 800)]
            let widthConstraint = visualView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.75)
            widthConstraint.priority = .defaultHigh
            regularConstraints.append(widthConstraint)
            
            if #available(iOS 11.0, *) {
                regularConstraints.append(visualView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -visualView.shadow.blur))
            } else {
                regularConstraints.append(visualView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: -visualView.shadow.blur))
            }
            
            regularConstraints += [
                visualView.contentView.topAnchor.constraint(equalTo: searchResultContainer.topAnchor),
                visualView.contentView.leftAnchor.constraint(equalTo: searchResultContainer.leftAnchor),
                visualView.contentView.bottomAnchor.constraint(equalTo: searchResultContainer.bottomAnchor),
                visualView.contentView.rightAnchor.constraint(equalTo: searchResultContainer.rightAnchor)]
        }
        
        NSLayoutConstraint.activate(regularConstraints)
    }
    
    // MARK: -
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ArticleTableCell
        let result = results[indexPath.row]
        
        cell.titleLabel.text = result.title
        cell.snippetLabel.text = result.snippet
        cell.snippetLabel.attributedText = result.attributedSnippet
        cell.faviconImageView.image = UIImage(data: Book.fetch(id: result.zimFileID, context: CoreDataContainer.shared.viewContext)?.favIcon ?? Data())
        cell.faviconImageView.contentMode = .scaleAspectFit

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let main = presentingViewController as? MainController else {return}
        
        if main.isShowingPanel && main.traitCollection.horizontalSizeClass == .compact { main.hidePanel() }
        main.tabsController.load(url: results[indexPath.row].url)
        main.searchController.isActive = false
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if results[indexPath.row].snippet != nil || results[indexPath.row].attributedSnippet != nil {
            return traitCollection.horizontalSizeClass == .regular ? 120 : 190
        } else {
            return 44
        }
    }
    
    // MARK: - UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text, self.searchText != searchText else {return}
        let procedure = SearchProcedure(term: searchText)
        procedure.add(condition: MutuallyExclusive<SearchResultController>())
        queue.add(operation: procedure)
    }
    
    // MARK: - ProcedureQueueDelegate
    
    func procedureQueue(_ queue: ProcedureQueue, willAddProcedure procedure: Procedure, context: Any?) -> ProcedureFuture? {
        if queue.operationCount == 0 {
            DispatchQueue.main.async {
                self.searchResultContainer.setContent(view: self.searchingView)
                self.searchingView.activityIndicator.startAnimating()
            }
        } else {
            queue.operations.forEach({$0.cancel()})
        }
        return nil
    }
    
    func procedureQueue(_ queue: ProcedureQueue, didFinishProcedure procedure: Procedure, withErrors errors: [Error]) {
        guard queue.operationCount == 0, let procedure = procedure as? SearchProcedure else {return}
        DispatchQueue.main.async {
            self.searchText = procedure.searchText
            self.results = procedure.sortedResults
            if self.results.count > 0 {
                self.searchingView.activityIndicator.stopAnimating()
                self.searchResultContainer.setContent(view: self.tableView)
                self.tableView.reloadData()
                self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
            } else if procedure.searchText == "" {
                self.searchResultContainer.setContent(view: self.searchNoTextController.view)
            } else {
                self.searchResultContainer.setContent(view: self.emptyResultView)
            }
        }
    }
}

private class SearchResultControllerBackgroundView: UIView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return subviews.map({ $0.frame.contains(point) }).reduce(false, { $0 || $1 })
    }
}

