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
    private let searchingView = SearchingView()
    private let searchNoTextController = SearchNoTextController()
    private let searchResultController = SearchResultController()
    
    var proportionalWidthConstraint: NSLayoutConstraint? = nil
    var equalWidthConstraint: NSLayoutConstraint? = nil
    var proportionalHeightConstraint: NSLayoutConstraint? = nil
    var bottomConstraint: NSLayoutConstraint? = nil
    
    private var viewHiddenObserver: NSKeyValueObservation?
    
    private let queue = ProcedureQueue()
    private(set) var searchText = ""
    
    // MARK: - Overrides
    
    override func loadView() {
        view = SearchResultControllerBackgroundView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        queue.delegate = self
        configureConstraints()
        visualView.contentView.isHidden = true
        
        addChildViewController(searchNoTextController)
        searchNoTextController.didMove(toParentViewController: self)
        addChildViewController(searchResultController)
        searchResultController.didMove(toParentViewController: self)
        
        viewHiddenObserver = view.observe(\.hidden, options: .new, changeHandler: { (view, change) in
            if change.newValue == true { view.isHidden = false }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(notification:)), name: .UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: .UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(notification:)), name: .UIKeyboardDidHide, object: nil)
        configureVisiualViewContent(mode: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardDidShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardDidHide, object: nil)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        guard traitCollection.horizontalSizeClass == .regular else {return}
        coordinator.animate(alongsideTransition: { (context) in
            self.visualView.isHidden = true
        }, completion: { (context) in
            self.visualView.isHidden = false
        })
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
    
    func configureVisiualViewContent(mode: SearchControllerMode?) {
        if let mode = mode {
            let view: UIView = {
                switch mode {
                case .onboarding:
                    return onboardingView
                case .noText:
                    return searchNoTextController.view
                case .searching:
                    return searchingView
                case .results:
                    return searchResultController.view
                case .noResult:
                    return emptyResultView
                }
            }()
            guard !visualView.contentView.subviews.contains(view) else {return}
            visualView.setContent(view: view)
        } else {
            if searchText.count == 0 && searchNoTextController.localBookIDs.count > 0 {
                configureVisiualViewContent(mode: .noText)
            } else if searchText.count == 0 && searchNoTextController.localBookIDs.count == 0 {
                configureVisiualViewContent(mode: .onboarding)
            } else if searchText.count >= 0 && searchResultController.results.count > 0 {
                configureVisiualViewContent(mode: .results)
            } else if searchText.count >= 0 && searchResultController.results.count == 0 {
                configureVisiualViewContent(mode: .noResult)
            } else {
                visualView.setContent(view: nil)
            }
        }
    }
    
    // MARK: - Keyboard
    
    @objc func keyboardWillShow(notification: Notification)  {
        if let firstSubView = visualView.contentView.subviews.first, firstSubView !== searchResultController.view {
            visualView.contentView.isHidden = true
        }
    }
    
    @objc func keyboardDidShow(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: NSValue],
            let origin = userInfo[UIKeyboardFrameEndUserInfoKey]?.cgRectValue.origin else {return}
        let point = visualView.contentView.convert(origin, from: nil)
        visualView.bottomInset = visualView.contentView.bounds.height - point.y
        visualView.contentView.isHidden = false
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        if let firstSubView = visualView.contentView.subviews.first, firstSubView !== searchResultController.view {
            visualView.contentView.isHidden = true
        }
        visualView.bottomInset = 0
    }
    
    @objc func keyboardDidHide(notification: Notification) {
        visualView.contentView.isHidden = false
    }
    
    // MARK: - UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text, searchText.count > 0, self.searchText != searchText else {return}
        let procedure = SearchProcedure(term: searchText, ids: searchNoTextController.includedInSearchBookIDs)
        procedure.add(condition: MutuallyExclusive<SearchController>())
        queue.add(operation: procedure)
    }
    
    // MARK: - ProcedureQueueDelegate
    
    func procedureQueue(_ queue: ProcedureQueue, willAddProcedure procedure: Procedure, context: Any?) -> ProcedureFuture? {
        if queue.operationCount == 0 {
            DispatchQueue.main.async {
                self.configureVisiualViewContent(mode: .searching)
                self.searchingView.activityIndicator.startAnimating()
            }
        } else {
            queue.operations.forEach({ $0.cancel() })
        }
        return nil
    }
    
    func procedureQueue(_ queue: ProcedureQueue, didFinishProcedure procedure: Procedure, withErrors errors: [Error]) {
        guard queue.operationCount == 0, let procedure = procedure as? SearchProcedure else {return}
        DispatchQueue.main.async {
            self.searchText = procedure.searchText
            self.searchResultController.results = procedure.sortedResults
            self.searchingView.activityIndicator.stopAnimating()
            
            if self.searchResultController.results.count > 0 {
                self.configureVisiualViewContent(mode: .results)
                self.searchResultController.tableView.reloadData()
                DispatchQueue.main.async {
                    self.searchResultController.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
                }
            } else {
                self.configureVisiualViewContent(mode: nil)
            }
        }
    }
}

private class SearchResultControllerBackgroundView: UIView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return subviews.map({ $0.frame.contains(point) }).reduce(false, { $0 || $1 })
    }
}

class SearchingView: UIView {
    let activityIndicator = UIActivityIndicatorView()
    
    convenience init() {
        self.init(frame: CGRect.zero)
        activityIndicator.activityIndicatorViewStyle = .gray
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)])
    }
}

enum SearchControllerMode {
    case onboarding, noText, searching, results, noResult
}
