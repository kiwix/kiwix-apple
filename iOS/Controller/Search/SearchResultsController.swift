//
//  SearchResultController.swift
//  Kiwix
//
//  Created by Chris Li on 4/18/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit
import RealmSwift

class SearchResultsController: UIViewController, UISearchResultsUpdating {
    private var displayMode: DisplayMode = .filter { didSet(oldValue) { configureStackView(oldDisplayMode: oldValue) } }
    private let queue = SearchQueue()
    private var viewAlwaysVisibleObserver: NSKeyValueObservation?
    
    private let stackView = UIStackView()
    private let informationView = InformationView()
    private let dividerView = DividerView()
    private let resultsListController = SearchResultsListController()
    private let filterController: UIViewController = SearchFilterController()
    
    private var filterControllerWidthConstraint: NSLayoutConstraint?
    private var filterControllerProportionalWidthConstraint: NSLayoutConstraint?
    
    private let zimFiles: Results<ZimFile>? = {
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            let predicate = NSPredicate(format: "stateRaw == %@ AND includedInSearch == true", ZimFile.State.onDevice.rawValue)
            return database.objects(ZimFile.self).filter(predicate)
        } catch { return nil }
    }()
    private var changeToken: NotificationToken?
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        stackView.axis = .horizontal
        stackView.alignment = .fill
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Overrides

    override func loadView() {
        view = UIView()
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }

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
        filterControllerProportionalWidthConstraint?.priority = UILayoutPriority(749)
        
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
        configureChangeToken()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        informationView.alpha = 0.0
        changeToken = nil
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        guard traitCollection != previousTraitCollection else {return}
        configureStackView()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        informationView.alpha = 0.0
        coordinator.animate(alongsideTransition: nil) { _ in
            self.informationView.alpha = 1.0
        }
    }
    
    // MARK: Configurations
    
    private func configureStackView(oldDisplayMode: DisplayMode? = nil) {
        guard displayMode != oldDisplayMode else {return}
        
        stackView.arrangedSubviews.forEach({ $0.removeFromSuperview() })
        if traitCollection.horizontalSizeClass == .regular {
            stackView.addArrangedSubview(filterController.view)
            stackView.addArrangedSubview(dividerView)
            filterControllerWidthConstraint?.isActive = true
            filterControllerProportionalWidthConstraint?.isActive = true
        } else if traitCollection.horizontalSizeClass == .compact {
            filterControllerWidthConstraint?.isActive = false
            filterControllerProportionalWidthConstraint?.isActive = false
        }
        
        informationView.displayMode = displayMode
        switch displayMode {
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
    
    private func configureChangeToken() {
        changeToken = zimFiles?.observe({ (changes) in
            guard case .update = changes,
                  let contentController = self.presentingViewController as? ContentController else { return }
            self.updateSearchResults(for: contentController.searchController)
        })
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
        queue.cancelAllOperations()
        guard let searchText = searchController.searchBar.text, searchText.count > 0 else {
            displayMode = .filter
            return
        }
        
        let zimFileIDs: Set<String> = {
            guard let result = zimFiles else { return Set() }
            return Set(result.map({ $0.id }))
        }()
        
        if displayMode == .results,
            searchText == resultsListController.searchText,
            zimFileIDs == resultsListController.zimFileIDs {
            return
        }
        displayMode = .inProgress
        
        let operation = SearchOperation(searchText: searchText, zimFileIDs: zimFileIDs)
        operation.completionBlock = { [weak self] in
            guard !operation.isCancelled else { return }
            DispatchQueue.main.sync {
                self?.resultsListController.update(searchText: searchText, zimFileIDs: zimFileIDs, results: operation.results)
                self?.displayMode = operation.results.count > 0 ? .results : .noResults
            }
        }
        queue.addOperation(operation)
    }
}

// MARK: - Views

fileprivate enum DisplayMode { case filter, inProgress, noResults, results }

fileprivate class InformationView: UIView {
    private let activityIndicator = UIActivityIndicatorView()
    var displayMode: DisplayMode = .filter { didSet(oldValue) { configure(oldDisplayMode: oldValue) } }
    
    convenience init() {
        self.init(frame: .zero)
        configure()
        if #available(iOS 13.0, *) {
            activityIndicator.style = .large
        } else {
            activityIndicator.style = .gray
        }
    }
    
    private func configure(oldDisplayMode: DisplayMode? = nil) {
        guard displayMode != oldDisplayMode else {return}
        if oldDisplayMode == .inProgress {
            activityIndicator.stopAnimating()
        }
        
        switch displayMode {
        case .filter:
            let container = makeStackedContainer([
                TitleLabel("No Search Results."),
                SubtitleLabel("Please enter some text to start a search."),
            ])
            setCenterView(container)
        case .inProgress:
            activityIndicator.startAnimating()
            setCenterView(activityIndicator)
        case .noResults:
            let container = makeStackedContainer([
                TitleLabel("No Search Results."),
                SubtitleLabel("Please update the search text or search filter."),
            ])
            setCenterView(container)
        default:
            break
        }
    }
        
    private func setCenterView(_ view: UIView?) {
        subviews.forEach({ $0.removeFromSuperview() })
        guard let view = view else {return}
        view.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(view)
        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
    
    private func makeStackedContainer(_ arrangedSubviews: [UIView]) -> UIStackView {
        let container = UIStackView(arrangedSubviews: arrangedSubviews)
        container.axis = .vertical
        container.alignment = .center
        container.spacing = 10
        return container
    }
        
    private class TitleLabel: UILabel {
        convenience init(_ text: String) {
            self.init()
            self.text = text
            font = UIFont.preferredFont(forTextStyle: .title2)
            if #available(iOS 13.0, *) {
                textColor = .secondaryLabel
            } else {
                textColor = .darkGray
            }
        }
    }
    
    private class SubtitleLabel: UILabel {
        convenience init(_ text: String) {
            self.init()
            self.text = text
            font = UIFont.preferredFont(forTextStyle: .title3)
            if #available(iOS 13.0, *) {
                textColor = .tertiaryLabel
            } else {
                textColor = .gray
            }
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
