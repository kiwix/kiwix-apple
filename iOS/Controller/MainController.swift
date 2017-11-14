//
//  MainViewController.swift
//  Kiwix
//
//  Created by Chris Li on 11/7/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class MainController: UIViewController, UISearchControllerDelegate, ToolBarControlEvents, TabContainerControllerDelegate {
    private (set) var isShowingPanel = false
    private var currentTabControllerObserver: NSKeyValueObservation?
    private lazy var cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelSearch))
    
    // MARK: - Controllers
    let search = UISearchController(searchResultsController: SearchResultController())
    private (set) var tabs: TabsController!
    private var toolBar: ToolBarController!
    private var panel: PanelController!
    private lazy var library = LibraryController()
    
    // MARK: - IBOutlet
    @IBOutlet weak var dimView: DimView!
    @IBOutlet weak var panelCompactShowConstraint: NSLayoutConstraint!
    @IBOutlet weak var panelCompactHideConstraint: NSLayoutConstraint!
    @IBOutlet weak var panelRegularShowConstraint: NSLayoutConstraint!
    @IBOutlet weak var panelRegularHideConstraint: NSLayoutConstraint!
    @IBOutlet weak var toolBarShowConstraints: NSLayoutConstraint!
    @IBOutlet weak var toolBarHideConstraints: NSLayoutConstraint!
    @IBOutlet weak var separatorViewWidthConstraints: NSLayoutConstraint!
    
    // MARK: - Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSearchController()
        toolBar.home.isSelected = true
        tabs.switchToHome()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        guard let identifier = segue.identifier else {return}
        switch identifier {
        case "TabContainerController":
            tabs = segue.destination as! TabsController
            tabs.delegate = self
        case "ToolBarController":
            toolBar = segue.destination as! ToolBarController
            toolBar.delegate = self
        case "PanelController":
            panel = segue.destination as! PanelController
        default:
            break
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass else {return}
        navigationItem.setRightBarButton(search.isActive && traitCollection.horizontalSizeClass == .compact ? cancelButton : nil, animated: false)
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
            toolBarShowConstraints.isActive = !isShowingPanel
            toolBarHideConstraints.isActive = isShowingPanel
        case .regular:
            NSLayoutConstraint.deactivate([panelCompactShowConstraint, panelCompactHideConstraint])
            panelRegularShowConstraint.isActive = isShowingPanel
            panelRegularHideConstraint.isActive = !isShowingPanel
            toolBarShowConstraints.isActive = true
            toolBarHideConstraints.isActive = false
        case .unspecified:
            break
        }
        super.updateViewConstraints()
    }
    
    // MARK: - Configure
    
    private func configureSearchController() {
        search.searchBar.searchBarStyle = .minimal
        search.searchBar.autocapitalizationType = .none
        search.searchBar.autocorrectionType = .no
        search.hidesNavigationBarDuringPresentation = false
        search.obscuresBackgroundDuringPresentation = true
        search.delegate = self
        search.searchResultsUpdater = search.searchResultsController as? SearchResultController
        navigationItem.titleView = search.searchBar
        self.definesPresentationContext = true
    }
    
    func showPanel(mode: PanelMode) {
        panel.set(mode: mode)
        switch mode {
        case .tableOfContent:
            toolBar.tableOfContent.isSelected = true
            toolBar.bookmark.isSelected = false
        case .bookmark:
            toolBar.tableOfContent.isSelected = false
            toolBar.bookmark.isSelected = true
        case .history:
            toolBar.tableOfContent.isSelected = false
            toolBar.bookmark.isSelected = false
        }
        
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
        toolBar.tableOfContent.isSelected = false
        toolBar.bookmark.isSelected = false
        
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
    
    @objc func cancelSearch() {
        search.isActive = false
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
    
    // MARK: - ToolBarDelegate
    
    func backButtonTapped() {
        tabs.current?.goBack()
    }

    func forwardButtonTapped() {
        tabs.current?.goForward()
    }
    
    func tableOfContentButtonTapped() {
        if panel.mode == .tableOfContent {
            hidePanel()
        } else {
            showPanel(mode: .tableOfContent)
            tabs.current?.getTableOfContent(completion: { (headings) in
                print(headings)
            })
        }
    }
    
    func bookmarkButtonTapped() {
        panel.mode != .bookmark ? showPanel(mode: .bookmark) : hidePanel()
    }
    
    func homeButtonTapped() {
        tabs.isDisplayingHome ? tabs.switchToCurrentTab() : tabs.switchToHome()
    }

    // MARK: - TabContainerControllerDelegate
    
    func homeWillBecomeCurrent() {
        toolBar.back.isEnabled = false
        toolBar.forward.isEnabled = false
        toolBar.home.isSelected = true
    }
    
    func tabWillBecomeCurrent(controller: UIViewController & TabController) {
        toolBar.back.isEnabled = controller.canGoBack
        toolBar.forward.isEnabled = controller.canGoForward
        toolBar.home.isSelected = false
    }
    
    func tabDidFinishLoading(controller: UIViewController & TabController) {
        toolBar.back.isEnabled = controller.canGoBack
        toolBar.forward.isEnabled = controller.canGoForward
    }
    
    func libraryButtonTapped() {
        present(library, animated: true, completion: nil)
    }
    
    func settingsButtonTapped() {
    }
}

class DimView: UIView {
    var isDimmed: Bool = false {
        didSet {
            backgroundColor = isDimmed ? UIColor.lightGray.withAlphaComponent(0.5) : UIColor.clear
        }
    }
}
