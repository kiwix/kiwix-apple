//
//  MainViewController.swift
//  Kiwix
//
//  Created by Chris Li on 11/7/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class MainController: UIViewController, UISearchControllerDelegate, ToolBarControlEvents, TabContainerControllerDelegate {
    let searchController = UISearchController(searchResultsController: SearchResultController())
    private (set) var tabs: TabsController!
    private var toolBar: ToolBarController!
    private var panel: PanelController!
    private lazy var libraryController = LibraryController()
    
    private var isShowingPanel = false
    private var currentTabControllerObserver: NSKeyValueObservation?
    private lazy var cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelSearch))
    
    @IBOutlet weak var dimView: DimView!
    @IBOutlet weak var panelCompactShowConstraint: NSLayoutConstraint!
    @IBOutlet weak var panelCompactHideConstraint: NSLayoutConstraint!
    @IBOutlet weak var panelRegularShowConstraint: NSLayoutConstraint!
    @IBOutlet weak var panelRegularHideConstraint: NSLayoutConstraint!
    @IBOutlet weak var toolBarShowConstraints: NSLayoutConstraint!
    @IBOutlet weak var toolBarHideConstraints: NSLayoutConstraint!
    @IBOutlet weak var separatorViewWidthConstraints: NSLayoutConstraint!
    
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
        navigationItem.setRightBarButton(searchController.isActive && traitCollection.horizontalSizeClass == .compact ? cancelButton : nil, animated: false)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        view.setNeedsUpdateConstraints()
    }
    
    override func updateViewConstraints() {
        separatorViewWidthConstraints.constant = 1 / UIScreen.main.scale
        switch self.traitCollection.horizontalSizeClass {
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
    
    private func configureSearchController() {
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.autocorrectionType = .no
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.obscuresBackgroundDuringPresentation = true
        searchController.delegate = self
        searchController.searchResultsUpdater = searchController.searchResultsController as? SearchResultController
        navigationItem.titleView = searchController.searchBar
        self.definesPresentationContext = true
    }
    
    private func togglePanel() {
        isShowingPanel = !isShowingPanel
        if isShowingPanel {
            dimView.isHidden = false
            dimView.isDimmed = false
        }
        
        view.layoutIfNeeded()
        view.setNeedsUpdateConstraints()
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseInOut, animations: {
            self.view.layoutIfNeeded()
            self.dimView.isDimmed = self.isShowingPanel
        }, completion: { _ in
            if !self.isShowingPanel {
                self.dimView.isHidden = true
            }
        })
    }
    
    @objc func cancelSearch() {
        searchController.isActive = false
    }
    
    @IBAction func dimViewTapped(_ sender: UITapGestureRecognizer) {
        togglePanel()
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
    
    // MARK: - ToolBar
    
    func backButtonTapped() {
        tabs.go(.back, in: .current)
    }

    func forwardButtonTapped() {
        tabs.go(.forward, in: .current)
    }
    
    func tableOfContentButtonTapped() {
        togglePanel()
    }
    
    func bookmarkButtonTapped() {
        
    }
    
    func homeButtonTapped() {
        tabs.isDisplayingHome ? tabs.switchToCurrentTab() : tabs.switchToHome()
        toolBar.home.isSelected = tabs.isDisplayingHome
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
        present(libraryController, animated: true, completion: nil)
    }
}

class DimView: UIView {
    var isDimmed: Bool = false {
        didSet {
            backgroundColor = isDimmed ? UIColor.lightGray.withAlphaComponent(0.5) : UIColor.clear
        }
    }
}
