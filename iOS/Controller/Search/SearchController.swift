//
//  SearchResultController.swift
//  Kiwix
//
//  Created by Chris Li on 11/7/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import CoreData
import ProcedureKit

class SearchController: UIViewController, UISearchResultsUpdating, ProcedureQueueDelegate {
    private let visualView = VisualEffectShadowView()
    private let onboardingView = EmptyContentView(image: #imageLiteral(resourceName: "MagnifyingGlass"), title: "Download some books to get started")
    private let emptyResultView = EmptyContentView(image: #imageLiteral(resourceName: "MagnifyingGlass"), title: "No Result")
    
    private let searchResultContainer = SearchResultContainerView()
    private let searchingView = SearchingView()
    private let searchResultController = SearchResultController()
    private let searchNoTextController = SearchNoTextController()
    
    var proportionalWidthConstraint: NSLayoutConstraint? = nil
    var equalWidthConstraint: NSLayoutConstraint? = nil
    var proportionalHeightConstraint: NSLayoutConstraint? = nil
    var bottomConstraint: NSLayoutConstraint? = nil
    
    private var observer: NSKeyValueObservation?
    
    private let queue = ProcedureQueue()
    private var booksIncludedInSearch = Set<ZimFileID>()
    private(set) var searchText = ""
    
    // MARK: - Overrides
    
    override func loadView() {
        view = SearchResultControllerBackgroundView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        queue.delegate = self
        configureConstraints()
        visualView.setContent(view: onboardingView)
        visualView.contentView.isHidden = true
        
//        searchResultContainer.isHidden = true
        
//        addChildViewController(searchNoTextController)
//        searchResultContainer.setContent(view: searchNoTextController.view)
//        searchNoTextController.didMove(toParentViewController: self)
//
//        addChildViewController(searchResultController)
//        searchResultController.didMove(toParentViewController: self)
        
        observer = view.observe(\.hidden, options: .new, changeHandler: { (view, change) in
            if change.newValue == true { view.isHidden = false }
        })
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(managedObjectContextObjectsDidChange(notification:)),
                                               name: .NSManagedObjectContextObjectsDidChange,
                                               object: CoreDataContainer.shared.viewContext)
        booksIncludedInSearch = Set(Book.fetch(states: [.local], context: CoreDataContainer.shared.viewContext).filter({ $0.includeInSearch }).map({ $0.id }))
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        guard traitCollection.horizontalSizeClass == .regular else {return}
        coordinator.animate(alongsideTransition: { (context) in
            self.visualView.isHidden = true
        }, completion: { (context) in
            self.visualView.isHidden = false
        })
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .NSManagedObjectContextObjectsDidChange, object: CoreDataContainer.shared.viewContext)
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
            visualView.roundingCorners = nil
            proportionalWidthConstraint?.priority = .defaultLow
            equalWidthConstraint?.priority = .defaultHigh
            proportionalHeightConstraint?.priority = .defaultLow
            bottomConstraint?.priority = .defaultHigh
            break
        case .regular:
            visualView.roundingCorners = .allCorners
            proportionalWidthConstraint?.priority = .defaultHigh
            equalWidthConstraint?.priority = .defaultLow
            proportionalHeightConstraint?.priority = .defaultHigh
            bottomConstraint?.priority = .defaultLow
        case .unspecified:
            break
        }
    }
    
    private func configureConstraints() {
        visualView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(visualView)
        
        visualView.contentView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        visualView.contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        visualView.widthAnchor.constraint(lessThanOrEqualToConstant: 800).isActive = true
        
        proportionalWidthConstraint = visualView.contentView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.75)
        proportionalWidthConstraint?.priority = traitCollection.horizontalSizeClass == .regular ? .defaultHigh : .defaultLow
        proportionalWidthConstraint?.isActive = true
        equalWidthConstraint = visualView.contentView.widthAnchor.constraint(equalTo: view.widthAnchor)
        equalWidthConstraint?.priority = traitCollection.horizontalSizeClass == .compact ? .defaultHigh : .defaultLow
        equalWidthConstraint?.isActive = true
        proportionalHeightConstraint = visualView.contentView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.75)
        proportionalHeightConstraint?.priority = traitCollection.horizontalSizeClass == .regular ? .defaultHigh : .defaultLow
        proportionalHeightConstraint?.isActive = true
        bottomConstraint = visualView.contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        bottomConstraint?.priority = traitCollection.horizontalSizeClass == .compact ? .defaultHigh : .defaultLow
        bottomConstraint?.isActive = true
    }
    
    // MARK: - Search Scope Observing
    
    @objc func managedObjectContextObjectsDidChange(notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        if let inserts = (userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>)?.flatMap({ $0 as? Book }) {
            inserts.forEach({ (book) in
                guard book.includeInSearch else {return}
                booksIncludedInSearch.insert(book.id)
            })
        }
        
        if let updates = (userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>)?.flatMap({ $0 as? Book }) {
            updates.forEach({ (book) in
                if book.includeInSearch {
                    booksIncludedInSearch.insert(book.id)
                } else {
                    booksIncludedInSearch.remove(book.id)
                }
            })
        }
        
        if let deletes = (userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>)?.flatMap({ $0 as? Book }) {
            deletes.forEach({ booksIncludedInSearch.remove($0.id) })
        }
    }
    
    // MARK: - Keyboard
    
    @objc func keyboardWillShow(notification: Notification)  {
        visualView.contentView.isHidden = true
        
//        if !searchResultContainer.subviews.contains(searchResultController.tableView) {
//            searchResultContainer.isHidden = true
//        }
    }
    
    @objc func keyboardDidShow(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: NSValue],
            let origin = userInfo[UIKeyboardFrameEndUserInfoKey]?.cgRectValue.origin else {return}
        let point = visualView.contentView.convert(origin, from: nil)
        visualView.bottomInset = visualView.contentView.bounds.height - point.y
        visualView.contentView.isHidden = false
//        guard let userInfo = notification.userInfo as? [String: NSValue],
//            let origin = userInfo[UIKeyboardFrameEndUserInfoKey]?.cgRectValue.origin else {return}
//        let point = searchResultContainer.convert(origin, from: nil)
//        searchResultContainer.bottomInset = searchResultContainer.frame.height - point.y
//        searchResultContainer.isHidden = false
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        visualView.contentView.isHidden = true
        visualView.bottomInset = 0
//        if !searchResultContainer.subviews.contains(searchResultController.tableView) {
//            searchResultContainer.isHidden = true
//        }
//        searchResultContainer.bottomInset = 0
    }
    
    @objc func keyboardDidHide(notification: Notification) {
        visualView.contentView.isHidden = false
//        searchResultContainer.isHidden = false
    }
    
    // MARK: - UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text, self.searchText != searchText else {return}
        let procedure = SearchProcedure(term: searchText, ids: booksIncludedInSearch)
        procedure.add(condition: MutuallyExclusive<SearchController>())
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
            self.searchResultController.results = procedure.sortedResults
            if self.searchResultController.results.count > 0 {
                self.searchingView.activityIndicator.stopAnimating()
                self.searchResultContainer.setContent(view: self.searchResultController.tableView)
                self.searchResultController.tableView.reloadData()
                DispatchQueue.main.async {
                    self.searchResultController.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
                }
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

