//
//  MainViewController.swift
//  Kiwix
//
//  Created by Chris Li on 11/7/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class MainController: UIViewController, UISearchControllerDelegate {
    private (set) var isShowingPanel = false
    @IBOutlet weak var dimView: DimView!
    private lazy var cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelSearchButtonTapped))

    // MARK: - Controllers
    
    let searchController = UISearchController(searchResultsController: SearchResultController())
    private(set) var tabContainerController: TabContainerController!
    private var panel: PanelController!
    private(set) lazy var libraryController = LibraryController()
    
    // MARK: - Constraints
    
    @IBOutlet weak var panelCompactShowConstraint: NSLayoutConstraint!
    @IBOutlet weak var panelCompactHideConstraint: NSLayoutConstraint!
    @IBOutlet weak var panelRegularShowConstraint: NSLayoutConstraint!
    @IBOutlet weak var panelRegularHideConstraint: NSLayoutConstraint!
    @IBOutlet weak var separatorViewWidthConstraints: NSLayoutConstraint!
    
    // MARK: - Toolbar
    
    private lazy var navigationBackButton = BarButtonItem(image: #imageLiteral(resourceName: "Left"), inset: 12, delegate: self)
    private lazy var navigationForwardButton = BarButtonItem(image: #imageLiteral(resourceName: "Right"), inset: 12, delegate: self)
    private lazy var tableOfContentButton = BarButtonItem(image: #imageLiteral(resourceName: "TableOfContent"), inset: 8, delegate: self)
    private lazy var bookmarkButton = BarButtonItem(image: #imageLiteral(resourceName: "Star"), highlightedImage: #imageLiteral(resourceName: "StarFilled"), inset: 8, delegate: self)
    private lazy var libraryButton = BarButtonItem(image: #imageLiteral(resourceName: "Library"), inset: 6, delegate: self)
    private lazy var settingButton = BarButtonItem(image: #imageLiteral(resourceName: "Setting"), inset: 8, delegate: self)
    
    // MARK: - Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSearchController()
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: .UIApplicationWillEnterForeground, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        guard let identifier = segue.identifier else {return}
        switch identifier {
        case "TabContainerController":
            tabContainerController = segue.destination as! TabContainerController
        case "PanelController":
            panel = segue.destination as! PanelController
        default:
            break
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass else {return}
        DispatchQueue.main.async { self.configureToolbar() }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        DispatchQueue.main.async { self.configureToolbar() }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        view.setNeedsUpdateConstraints()
    }
    
    override func updateViewConstraints() {
        separatorViewWidthConstraints.constant = 1 / UIScreen.main.scale
        switch traitCollection.horizontalSizeClass {
        case .compact:
            NSLayoutConstraint.deactivate([panelRegularShowConstraint, panelRegularHideConstraint])
            panelCompactShowConstraint.isActive = isShowingPanel
            panelCompactHideConstraint.isActive = !isShowingPanel
        case .regular:
            NSLayoutConstraint.deactivate([panelCompactShowConstraint, panelCompactHideConstraint])
            panelRegularShowConstraint.isActive = isShowingPanel
            panelRegularHideConstraint.isActive = !isShowingPanel
        case .unspecified:
            break
        }
        super.updateViewConstraints()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .UIApplicationWillEnterForeground, object: nil)
    }
    
    // MARK: -
    
    private func configureSearchController() {
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.autocorrectionType = .no
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.obscuresBackgroundDuringPresentation = true
        searchController.delegate = self
        searchController.searchResultsUpdater = searchController.searchResultsController as? SearchResultController
        navigationItem.titleView = searchController.searchBar
        definesPresentationContext = true
    }
    
    @objc func cancelSearchButtonTapped() {
        searchController.isActive = false
    }
    
    @objc func appWillEnterForeground() {
        DispatchQueue.main.async { self.configureToolbar() }
    }
    
    @IBAction func dimViewTapped(_ sender: UITapGestureRecognizer) {
        hidePanel()
    }
    
    // MARK: - UISearchControllerDelegate
    
    func willPresentSearchController(_ searchController: UISearchController) {
        guard UIDevice.current.userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .compact else {return}
        navigationItem.setRightBarButton(cancelButton, animated: true)
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        guard UIDevice.current.userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .compact else {return}
        navigationItem.setRightBarButton(nil, animated: true)
    }
    
    // MARK: - Panel
    
    func showPanel(mode: PanelMode) {
        panel.set(mode: mode)
//        switch mode {
//        case .tableOfContent:
//            toolBar.tableOfContent.isSelected = true
//            toolBar.bookmark.isSelected = false
//        case .bookmark:
//            toolBar.tableOfContent.isSelected = false
//            toolBar.bookmark.isSelected = true
//        case .history:
//            toolBar.tableOfContent.isSelected = false
//            toolBar.bookmark.isSelected = false
//        }
        
        guard !isShowingPanel else {return}
        isShowingPanel = true
        dimView.isHidden = false
        dimView.isDimmed = false
        
        view.layoutIfNeeded()
        view.setNeedsUpdateConstraints()
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseInOut, animations: {
            self.view.layoutIfNeeded()
            self.dimView.isDimmed = true
        })
    }
    
    func hidePanel() {
        panel.set(mode: nil)
//        toolBar.tableOfContent.isSelected = false
//        toolBar.bookmark.isSelected = false
        
        guard isShowingPanel else {return}
        isShowingPanel = false
        view.layoutIfNeeded()
        view.setNeedsUpdateConstraints()
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseInOut, animations: {
            self.view.layoutIfNeeded()
            self.dimView.isDimmed = false
        }, completion: { _ in
            self.dimView.isHidden = true
        })
    }
    
    
    
    
    

    // MARK: - TabContainerControllerDelegate
    
//    func homeWillBecomeCurrent() {
//        toolBar.back.isEnabled = false
//        toolBar.forward.isEnabled = false
//        toolBar.home.isSelected = true
//    }
    
//    func tabWillBecomeCurrent(controller: UIViewController & WebViewController) {
//        toolBar.back.isEnabled = controller.canGoBack
//        toolBar.forward.isEnabled = controller.canGoForward
//        toolBar.home.isSelected = false
//    }
    
//    func tabDidFinishLoading(controller: UIViewController & WebViewController) {
//        toolBar.back.isEnabled = controller.canGoBack
//        toolBar.forward.isEnabled = controller.canGoForward
//    }
}

extension MainController: BarButtonItemDelegate {
    private func configureToolbar() {
        toolbarItems = nil
        navigationItem.leftBarButtonItems = nil
        navigationItem.rightBarButtonItems = nil
        if traitCollection.horizontalSizeClass == .regular {
            navigationController?.isToolbarHidden = true
            navigationItem.leftBarButtonItems = [navigationBackButton, navigationForwardButton, tableOfContentButton]
            navigationItem.rightBarButtonItems = [settingButton, libraryButton, bookmarkButton]
        } else if traitCollection.horizontalSizeClass == .compact {
            navigationController?.isToolbarHidden = false
            toolbarItems = [navigationBackButton, navigationForwardButton, tableOfContentButton, bookmarkButton, libraryButton, settingButton].enumerated()
                .reduce([], { $0 + ($1.offset > 0 ? [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), $1.element] : [$1.element]) })
            if searchController.isActive {
                navigationItem.setRightBarButton(cancelButton, animated: false)
            }
        }
    }
    
    func buttonTapped(item: BarButtonItem, button: UIButton) {
        switch item {
        case navigationBackButton:
            break
        case navigationForwardButton:
            break
        case tableOfContentButton:
            break
        case bookmarkButton:
            break
        case libraryButton:
            present(libraryController, animated: true, completion: nil)
        case settingButton:
            break
        default:
            break
        }
    }
    
//    func tableOfContentButtonTapped() {
//        if panel.mode == .tableOfContent {
//            hidePanel()
//        } else {
//            showPanel(mode: .tableOfContent)
//            //            container.current?.getTableOfContent(completion: { (headings) in
//            //                self.panel.tableOfContent?.headings = headings
//            //            })
//        }
//    }
//
//    func bookmarkButtonTapped() {
//        panel.mode != .bookmark ? showPanel(mode: .bookmark) : hidePanel()
//    }
}
