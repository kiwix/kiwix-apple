//
//  MainViewController.swift
//  Kiwix
//
//  Created by Chris Li on 11/7/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class MainViewController: UIViewController, UISearchControllerDelegate, ToolBarControlEvents {
    let searchController = UISearchController(searchResultsController: SearchResultController())
    var tabContainerController: TabContainerController!
    var toolBarController: ToolBarController!
    var tableOfContentController: TableOfContentController!
    private lazy var cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelSearch))
    
    private var isShowingTableOfContent = false
    
    @IBOutlet weak var dimView: DimView!
    @IBOutlet weak var panelContainer: UIView!
    @IBOutlet weak var toolBarContainer: UIView!
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
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        guard let identifier = segue.identifier else {return}
        switch identifier {
        case "TabContainerController":
            break
        case "ToolBarController":
            toolBarController = segue.destination as! ToolBarController
            toolBarController.delegate = self
        case "TableOfContentController":
            break
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
            panelCompactShowConstraint.isActive = isShowingTableOfContent
            panelCompactHideConstraint.isActive = !isShowingTableOfContent
            toolBarShowConstraints.isActive = !isShowingTableOfContent
            toolBarHideConstraints.isActive = isShowingTableOfContent
        case .regular:
            NSLayoutConstraint.deactivate([panelCompactShowConstraint, panelCompactHideConstraint])
            panelRegularShowConstraint.isActive = isShowingTableOfContent
            panelRegularHideConstraint.isActive = !isShowingTableOfContent
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
    
    private func toggleTableOfContent() {
        isShowingTableOfContent = !isShowingTableOfContent
        if isShowingTableOfContent {
            dimView.isHidden = false
            dimView.isDimmed = false
        }
        
        view.layoutIfNeeded()
        view.setNeedsUpdateConstraints()
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseInOut, animations: {
            self.view.layoutIfNeeded()
            self.dimView.isDimmed = self.isShowingTableOfContent
        }, completion: { _ in
            if !self.isShowingTableOfContent {
                self.dimView.isHidden = true
            }
        })
    }
    
    @objc func cancelSearch() {
        searchController.isActive = false
    }
    
    @IBAction func dimViewTapped(_ sender: UITapGestureRecognizer) {
        toggleTableOfContent()
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
//        tabContainerController.currentTabController?.goBack()
    }

    func forwardButtonTapped() {
//        tabContainerController.currentTabController?.goForward()
    }
    
    func tableOfContentButtonTapped() {
        toggleTableOfContent()
    }
    
    func homeButtonTapped() {
//        tabContainerController.currentTabController?.loadMainPage()
    }

    func libraryButtonTapped() {
//        present(libraryController, animated: true, completion: nil)
    }
    
}

class DimView: UIView {
    var isDimmed: Bool = false {
        didSet {
            backgroundColor = isDimmed ? UIColor.lightGray.withAlphaComponent(0.5) : UIColor.clear
        }
    }
}
