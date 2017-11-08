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
    
    @IBOutlet weak var tableOfContentCompactShowConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableOfContentCompactHideConstraint: NSLayoutConstraint!
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
        switch self.traitCollection.horizontalSizeClass {
        case .compact:
            if UIDevice.current.userInterfaceIdiom == .pad {
                navigationItem.setRightBarButton(searchController.isActive ? cancelButton : nil, animated: false)
            }
        case .regular:
            navigationItem.setRightBarButton(nil, animated: false)
        case .unspecified:
            break
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        switch self.traitCollection.horizontalSizeClass {
        case .compact:
            tableOfContentCompactShowConstraint.isActive = isShowingTableOfContent
            tableOfContentCompactHideConstraint.isActive = !isShowingTableOfContent
        case .regular:
            break
        case .unspecified:
            break
        }
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
        tableOfContentCompactShowConstraint.isActive = isShowingTableOfContent
        tableOfContentCompactHideConstraint.isActive = !isShowingTableOfContent
        
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
