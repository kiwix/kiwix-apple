//
//  RootViewController.swift
//  Kiwix
//
//  Created by Chris Li on 11/28/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import UIKit

class RootViewController: UIViewController, UISearchControllerDelegate {
    private let searchController: UISearchController
    private let searchResultsController: SearchResultsController
    
    // MARK: Buttons
    
    private let chevronLeftButton = BarButton(imageName: "chevron.left")
    private let chevronRightButton = BarButton(imageName: "chevron.right")
    private let outlineButton = BarButton(imageName: "list.bullet")
    private let bookmarkButton = BookmarkButton(imageName: "star", bookmarkedImageName: "star.fill")
    private let diceButton = BarButton(imageName: "die.face.5")
    private let houseButton = BarButton(imageName: "house")
    private let libraryButton = BarButton(imageName: "folder")
    private let settingButton = BarButton(imageName: "gear")
    private let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
    private let bookmarkLongPressGestureRecognizer = UILongPressGestureRecognizer()
    
    init() {
        self.searchResultsController = SearchResultsController()
        self.searchController = UISearchController(searchResultsController: self.searchResultsController)
        
        super.init(nibName: nil, bundle: nil)
        
        // wire up button actions
        cancelButton.target = self
        cancelButton.action = #selector(dismissSearch)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureBarButtons(searchIsActive: searchController.isActive, animated: false)
        
        // background color
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        
        // search controller
        searchController.delegate = self
        searchController.searchBar.autocorrectionType = .no
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.searchBarStyle = .minimal
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchResultsUpdater = searchResultsController
        if #available(iOS 13.0, *) {
            searchController.automaticallyShowsCancelButton = false
            searchController.showsSearchResultsController = true
        }
        definesPresentationContext = true
        navigationItem.titleView = searchController.searchBar
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        configureBarButtons(searchIsActive: searchController.isActive, animated: false)
    }
    
    // MARK: - Configurations
    
    private func configureBarButtons(searchIsActive: Bool, animated: Bool) {
        if searchIsActive {
            navigationItem.setLeftBarButton(nil, animated: animated)
            navigationItem.setRightBarButton(cancelButton, animated: animated)
            setToolbarItems(nil, animated: animated)
            navigationController?.setToolbarHidden(true, animated: animated)
        } else if traitCollection.horizontalSizeClass == .regular {
            let left = BarButtonGroup(buttons: [chevronLeftButton, chevronRightButton, outlineButton, bookmarkButton], spacing: 10)
            let right = BarButtonGroup(buttons: [diceButton, houseButton, libraryButton, settingButton], spacing: 10)
            navigationItem.setLeftBarButton(UIBarButtonItem(customView: left), animated: animated)
            navigationItem.setRightBarButton(UIBarButtonItem(customView: right), animated: animated)
            setToolbarItems(nil, animated: animated)
            navigationController?.setToolbarHidden(true, animated: animated)
        } else if traitCollection.horizontalSizeClass == .compact {
            let group = BarButtonGroup(buttons: [
                chevronLeftButton, chevronRightButton, outlineButton, bookmarkButton, libraryButton, settingButton,
            ])
            navigationItem.setLeftBarButton(nil, animated: animated)
            navigationItem.setRightBarButton(nil, animated: animated)
            setToolbarItems([UIBarButtonItem(customView: group)], animated: animated)
            navigationController?.setToolbarHidden(false, animated: animated)
        } else {
            navigationItem.setLeftBarButton(nil, animated: animated)
            navigationItem.setRightBarButton(nil, animated: animated)
            setToolbarItems(nil, animated: animated)
            navigationController?.setToolbarHidden(true, animated: animated)
        }
    }
    
    // MARK: - UISearchControllerDelegate
    
    func willPresentSearchController(_ searchController: UISearchController) {
        configureBarButtons(searchIsActive: true, animated: true)
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        configureBarButtons(searchIsActive: false, animated: true)
    }
    
    // MARK: - Actions
    
    @objc func dismissSearch() {
        /*
         We have to dismiss the `searchController` first, so that the `isBeingDismissed` property is correct on the
         `searchResultsController`. We rely on `isBeingDismissed` to understand if the search text is cleared because
         of user tapped cancel button or manually cleared the serach field.
         */
        searchController.dismiss(animated: true)
        searchController.isActive = false
    }
}
