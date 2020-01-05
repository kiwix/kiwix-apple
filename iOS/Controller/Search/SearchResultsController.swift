//
//  SearchResultControllerNew.swift
//  Kiwix for iOS
//
//  Created by Chris Li on 4/18/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit
import RealmSwift

class SearchResultsController: UIViewController, UISearchResultsUpdating, SearchQueueEvents {
    private var mode: Mode = .filter { didSet { configureStackView() } }
    private let queue = SearchQueue()
    private var viewAlwaysVisibleObserver: NSKeyValueObservation?
    
    private let stackView = UIStackView()
    private let informationView = InfoStackView()
    private let dividerView = DividerView()
    private let filterController = SearchFilterController()
    private let resultsListController = SearchResultsListController()
    
    private var filterControllerWidthConstraint: NSLayoutConstraint?
    private var filterControllerProportionalWidthConstraint: NSLayoutConstraint?
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        queue.eventDelegate = self
        stackView.axis = .horizontal
        stackView.alignment = .fill
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Overrides

    override func loadView() {
        view = UIView()
        view.backgroundColor = .groupTableViewBackground

        if #available(iOS 13, *) {} else {
            /* Prevent SearchResultsController view from being automatically hidden by UISearchController */
            viewAlwaysVisibleObserver = view.observe(\.isHidden, options: .new, changeHandler: { (view, change) in
                if change.newValue == true { view.isHidden = false }
            })
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // filter controller width constraints for horizontal regular
        filterControllerWidthConstraint = filterController.view.widthAnchor.constraint(greaterThanOrEqualToConstant: 320)
        filterControllerProportionalWidthConstraint = filterController.view.widthAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.3)
        filterControllerProportionalWidthConstraint?.priority = .init(rawValue: 749)
        
        // stack view layout
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stackView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            stackView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
        ])
        
        // add child controllers
        addChild(filterController)
        addChild(resultsListController)
        filterController.didMove(toParent: self)
        resultsListController.didMove(toParent: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(notification:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        informationView.alpha = 0.0
        configureStackView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        informationView.alpha = 0.0
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        guard traitCollection != previousTraitCollection else {return}
        configureStackView()
    }
    
    // MARK: View configuration
    
    private func configureStackView() {
        stackView.arrangedSubviews.forEach({ $0.removeFromSuperview() })
        if traitCollection.horizontalSizeClass == .regular {
            stackView.addArrangedSubview(filterController.view)
            stackView.addArrangedSubview(DividerView())
            
            filterControllerWidthConstraint?.isActive = true
            filterControllerProportionalWidthConstraint?.isActive = true
        } else if traitCollection.horizontalSizeClass == .compact {
            filterControllerWidthConstraint?.isActive = false
            filterControllerProportionalWidthConstraint?.isActive = false
        }
        
        informationView.configure(mode: mode)
        switch mode {
        case .filter:
            if traitCollection.horizontalSizeClass == .regular {
                stackView.addArrangedSubview(informationView)
            } else if traitCollection.horizontalSizeClass == .compact {
                stackView.addArrangedSubview(filterController.view)
            }
        case .results:
            stackView.addArrangedSubview(resultsListController.view)
        case .inProgress, .noResults:
            stackView.addArrangedSubview(informationView)
        }
    }
    
    // MARK: Keyboard Events
    
    private func updateAdditionalSafeAreaInsets(notification: Notification, animated: Bool) {
        guard let userInfo = notification.userInfo,
            let keyboardEndFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {return}
        let keyboardEndFrameInView = view.convert(keyboardEndFrame, from: nil)
        let safeAreaFrame = view.safeAreaLayoutGuide.layoutFrame.insetBy(dx: 0, dy: -additionalSafeAreaInsets.bottom)
        let intersection = safeAreaFrame.intersection(keyboardEndFrameInView)
        
        let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
        let animationCurveRawValue = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue
        let options = UIView.AnimationOptions(rawValue: animationCurveRawValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue)
        let updates = {
            self.additionalSafeAreaInsets.bottom = intersection.height
            self.view.layoutIfNeeded()
        }
        
        if animated {
            UIView.animate(withDuration: duration, delay: 0.0, options: options,
                           animations: updates, completion: nil)
        } else {
            updates()
        }
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        updateAdditionalSafeAreaInsets(notification: notification, animated: true)
    }
    
    @objc func keyboardDidShow(notification: Notification) {
        updateAdditionalSafeAreaInsets(notification: notification, animated: false)
        if informationView.alpha == 0.0 { informationView.alpha = 1.0 }
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        updateAdditionalSafeAreaInsets(notification: notification, animated: true)
    }
    
    // MARK: UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else {return}
        print("updateSearchResults, searchText = \(searchText)")
        
        if searchText == "" {
            queue.cancelAllOperations()
            if !searchController.isBeingDismissed {
                mode = .filter
            }
            return
        }
        
        // Perform the search
        queue.enqueue(searchText: searchText, zimFileIDs: Set())
    }
    
    // MARK: SearchQueueEvents
    
    func searchStarted() {
        informationView.activityIndicator.startAnimating()
        mode = .inProgress
    }
    
    func searchFinished(searchText: String, results: [SearchResult]) {
        resultsListController.update(searchText: searchText, results: results)
        informationView.activityIndicator.stopAnimating()
        mode = results.count > 0 ? .results : .noResults
    }
}

// MARK: -

fileprivate enum Mode {
    case filter, inProgress, noResults, results
}

fileprivate class InfoStackView: UIStackView {
    let activityIndicator = UIActivityIndicatorView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        axis = .vertical
        alignment = .center
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(mode: Mode) {
        arrangedSubviews.forEach({ $0.removeFromSuperview() })
        switch mode {
        case .filter:
            addArrangedSubview(TitleLabel("Start a search"))
        case .inProgress:
            activityIndicator.startAnimating()
            addArrangedSubview(activityIndicator)
        case .noResults:
            addArrangedSubview(TitleLabel("No Result"))
        default:
            break
        }
    }
    
    class TitleLabel: UILabel {
        convenience init(_ text: String) {
            self.init()
            self.text = text
        }
    }
}

fileprivate class DividerView: UIView {
    init() {
        super.init(frame: .zero)
        if #available(iOS 13.0, *) {
            backgroundColor = .separator
        } else {
            backgroundColor = .gray
        }
        widthAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


class SearchResultsControllerOld: UIViewController, SearchQueueEvents, UISearchResultsUpdating {
    private let queue = SearchQueue()
    private let visualView = VisualEffectShadowView()
    let contentController = SearchResultContents()
    private var viewAlwaysVisibleObserver: NSKeyValueObservation?
    
    // MARK: - Constraints
    
    var readableContentWidthConstraint: NSLayoutConstraint? = nil
    var equalWidthConstraint: NSLayoutConstraint? = nil
    var proportionalHeightConstraint: NSLayoutConstraint? = nil
    var bottomConstraint: NSLayoutConstraint? = nil
    
    // MARK: - Database
    
    private let localZimFiles: Results<ZimFile>? = {
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            let predicate = NSPredicate(format: "stateRaw == %@", ZimFile.State.local.rawValue)
            return database.objects(ZimFile.self).filter(predicate)
        } catch { return nil }
    }()
    
    private let localIncludedInSearchZimFiles: Results<ZimFile>? = {
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            let predicate = NSPredicate(format: "stateRaw == %@ AND includeInSearch == true", ZimFile.State.local.rawValue)
            return database.objects(ZimFile.self).filter(predicate)
        } catch { return nil }
    }()
    
    // MARK: - Overrides
    
    override func loadView() {
        view = BackgroundView()
        
        if #available(iOS 13, *) {} else {
            /* Prevent SearchResultsController view from being automatically hidden by the UISearchController */
            viewAlwaysVisibleObserver = view.observe(\.isHidden, options: .new, changeHandler: { (view, change) in
                if change.newValue == true { view.isHidden = false }
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        edgesForExtendedLayout = []
        configureChildViewControllers()
        configureConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(notification:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(notification:)), name: UIResponder.keyboardDidHideNotification, object: nil)
        queue.eventDelegate = self
        configureVisualView()
        configureContent()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidHideNotification, object: nil)
        queue.eventDelegate = nil
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass else {return}
        configureVisualView()
        updateConstraintPriorities()
    }
    
    // MARK: - Keyboard Events
    
    @objc func keyboardDidShow(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: NSValue],
            let origin = userInfo[UIResponder.keyboardFrameEndUserInfoKey]?.cgRectValue.origin else {return}
        let point = visualView.contentView.convert(origin, from: nil)
        visualView.bottomInset = visualView.contentView.bounds.height - point.y
        if contentController.view.isHidden { contentController.view.isHidden = false }
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        visualView.bottomInset = 0
        if !contentController.mode.canScroll {
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
                self.contentController.view.isHidden = true
            }, completion: nil)
        }
    }
    
    @objc func keyboardDidHide(notification: Notification) {
        contentController.view.isHidden = false
    }
    
    // MARK: - View Manipulation
    
    private func configureVisualView() {
        switch traitCollection.horizontalSizeClass {
        case .compact:
            if #available(iOS 13.0, *) {
                visualView.contentView.backgroundColor = .systemBackground
            } else {
                visualView.contentView.backgroundColor = .white
            }
            visualView.roundingCorners = nil
        case .regular:
            visualView.contentView.backgroundColor = .clear
            visualView.roundingCorners = .allCorners
        default:
            break
        }
    }
    
    private func configureChildViewControllers() {
        guard !children.contains(contentController) else {return}
        addChild(contentController)
        contentController.didMove(toParent: self)
    }
    
    private func configureConstraints() {
        guard !view.subviews.contains(visualView) else {return}
        view.subviews.forEach({ $0.removeFromSuperview() })
        
        visualView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(visualView)
        contentController.view.translatesAutoresizingMaskIntoConstraints = false
        visualView.setContent(view: contentController.view)
        
        visualView.contentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        visualView.contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        readableContentWidthConstraint = visualView.contentView.widthAnchor.constraint(equalTo: view.readableContentGuide.widthAnchor, multiplier: 1.0, constant: 90)
        equalWidthConstraint = visualView.contentView.widthAnchor.constraint(equalTo: view.widthAnchor)
        proportionalHeightConstraint = visualView.contentView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.75)
        bottomConstraint = visualView.contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        
        updateConstraintPriorities()
        
        readableContentWidthConstraint?.isActive = true
        equalWidthConstraint?.isActive = true
        proportionalHeightConstraint?.isActive = true
        bottomConstraint?.isActive = true
    }
    
    private func updateConstraintPriorities() {
        readableContentWidthConstraint?.priority = traitCollection.horizontalSizeClass == .regular ? .defaultHigh : .defaultLow
        equalWidthConstraint?.priority = traitCollection.horizontalSizeClass == .compact ? .defaultHigh : .defaultLow
        proportionalHeightConstraint?.priority = traitCollection.horizontalSizeClass == .regular ? .defaultHigh : .defaultLow
        bottomConstraint?.priority = traitCollection.horizontalSizeClass == .compact ? .defaultHigh : .defaultLow
    }
    
    private func configureContent(mode: SearchResultContents.Mode? = nil) {
        if let mode = mode {
            contentController.mode = mode
            /*
             If `tabController.view` has never been on screen,
             and its content is searching, noResult or onboarding,
             we need to hide `tabController.view` here and unhide it after we adjust `visualView.bottomInset` in `keyboardDidShow`,
             so that `tabController.view` does not visiually jump.
             */
            if viewIfLoaded?.window == nil && !mode.canScroll {
                contentController.view.isHidden = true
            }
        } else {
            if queue.operationCount > 0 {
                // search is in progress
                configureContent(mode: .inProgress)
            } else if contentController.resultsListController.searchText == "" {
                if let localZimFileCount = localZimFiles?.count, localZimFileCount > 0 {
                    configureContent(mode: .noText)
                } else {
                    configureContent(mode: .onboarding)
                }
            } else {
                if contentController.resultsListController.results.count > 0 {
                    configureContent(mode: .results)
                } else {
                    configureContent(mode: .noResult)
                }
            }
        }
    }
    
    // MARK: - UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else {return}
        
        /* UISearchController will update results using empty string when it is being dismissed.
         We choose not to do so in order to preserve user's previous search text. */
        if searchController.isBeingDismissed && searchText == "" {return}
        
        /* If UISearchController is not being dismissed and the search text is set to empty string,
         that means user is trying to clear the search field. We immediately cancel all search tasks
         and change content back to no text mode. */
        if !searchController.isBeingDismissed && searchText == "" {
            queue.cancelAllOperations()
            configureContent(mode: .noText)
            contentController.resultsListController.update(searchText: "", results: [])
            return
        }
        
        /* If there is no search operation in queue (no pending result updates which makes current cached result up to date)
         and search text is the same as search text of cached result, we don't have to redo the search. */
        if queue.operationCount == 0 && searchText == contentController.resultsListController.searchText {return}

        /* Perform the search! */
        let zimFileIDs: Set<String> = {
            guard let result = localIncludedInSearchZimFiles else { return Set() }
            return Set(result.map({ $0.id }))
        }()
        queue.enqueue(searchText: searchText, zimFileIDs: zimFileIDs)
    }

    // MARK: - SearchQueueEvents
    
    func searchStarted() {
        configureContent(mode: .inProgress)
    }
    
    func searchFinished(searchText: String, results: [SearchResult]) {
        contentController.resultsListController.update(searchText: searchText, results: results)
        configureContent()
    }
    
    // MARK: - Type Definition
    
    private class BackgroundView: UIView {
        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            let view = super.hitTest(point, with: event)
            return view === self ? nil : view
        }
    }
}
