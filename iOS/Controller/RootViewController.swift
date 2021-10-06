//
//  RootViewController.swift
//  Kiwix
//
//  Created by Chris Li on 11/28/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import SwiftUI
import UIKit
import WebKit
import SafariServices
import Defaults
import RealmSwift

class RootViewController: UIViewController, UISearchControllerDelegate, UISplitViewControllerDelegate {
    let searchController: UISearchController
    private let sidebarController = SidebarController()
    private let searchResultsController: UIViewController & UISearchResultsUpdating
    private let welcomeController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WelcomeController") as! WelcomeController
    private let webViewController = WebViewController()
    
    private let onDeviceZimFiles = Queries.onDeviceZimFiles()?.sorted(byKeyPath: "size", ascending: false)
    private let buttonProvider: ButtonProvider
    
    // MARK: - Init & Overrides
    
    init() {
        self.searchResultsController = SearchResultsHostingController()
        self.searchController = UISearchController(searchResultsController: self.searchResultsController)
        self.buttonProvider = ButtonProvider(webView: webViewController.webView)
        super.init(nibName: nil, bundle: nil)
        buttonProvider.rootViewController = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureBarButtons(searchIsActive: searchController.isActive, animated: false)
        configureSidebarViewController()
        configureSearchController()
        
        if #available(iOS 14.0, *), FeatureFlags.homeViewEnabled {
            let homeViewController = UIHostingController(rootView: HomeView())
            homeViewController.rootView.zimFileTapped = openMainPage
            homeViewController.rootView.libraryButtonTapped = libraryButtonTapped
            homeViewController.rootView.settingsButtonTapped = settingsButtonTapped
            sidebarController.setContentViewController(homeViewController)
        } else {
            sidebarController.setContentViewController(welcomeController)
        }
        
        
        if #available(iOS 15.0, *) {
            navigationItem.scrollEdgeAppearance = {
                let apperance = UINavigationBarAppearance()
                apperance.configureWithDefaultBackground()
                return apperance
            }()
            navigationController?.toolbar.scrollEdgeAppearance = {
                let apperance = UIToolbarAppearance()
                apperance.configureWithDefaultBackground()
                return apperance
            }()
        }
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        if newCollection.horizontalSizeClass == .regular {
            // dismiss presented outline and bookmark controller from when view was horizontally compact
            if let navigationController = presentedViewController as? UINavigationController,
               let topViewController = navigationController.topViewController,
               (topViewController is OutlineViewController || topViewController is BookmarksViewController) {
                presentedViewController?.dismiss(animated: false)
            }
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        configureBarButtons(searchIsActive: searchController.isActive, animated: false)
    }
    
    // MARK: - Public
    
    func openURL(_ url: URL) {
        guard url.isKiwixURL else { return }
        if url.host == "search" {
            searchController.isActive = true
            searchController.searchBar.text = url.pathComponents.last
        } else {
            webViewController.webView.load(URLRequest(url: url))
            sidebarController.setContentViewController(webViewController)
            if searchController.isActive {
                dismissSearch()
            }
            presentedViewController?.dismiss(animated: true)
        }
    }
    
    func openFileURL(_ url: URL, canOpenInPlace: Bool) {
        guard url.isFileURL else {return}
        dismiss(animated: false)
        if ZimFileService.getMetaData(url: url) != nil {
            let fileImportController = FileImportController(fileURL: url, canOpenInPlace: canOpenInPlace)
            present(fileImportController, animated: true)
        } else {
            present(FileImportAlertController(fileName: url.lastPathComponent), animated: true)
        }
    }
    
    func openMainPage(zimFileID: String) {
        guard let url = ZimFileService.shared.getMainPageURL(zimFileID: zimFileID) else { return }
        openURL(url)
    }
    
    func openRandomPage(zimFileID: String? = nil) {
        guard let zimFileID = zimFileID ?? onDeviceZimFiles?.map({ $0.fileID }).randomElement(),
              let url = ZimFileService.shared.getRandomPageURL(zimFileID: zimFileID) else { return }
        openURL(url)
    }
    
    // MARK: - Setup & Configurations
    
    private func configureBarButtons(searchIsActive: Bool, animated: Bool) {
        if searchIsActive {
            navigationItem.setLeftBarButton(nil, animated: animated)
            navigationItem.setRightBarButton(buttonProvider.cancelButton, animated: animated)
            setToolbarItems(nil, animated: animated)
            navigationController?.setToolbarHidden(true, animated: animated)
        } else if traitCollection.horizontalSizeClass == .regular {
            let left = BarButtonGroup(buttons: buttonProvider.navigationLeftButtons, spacing: 12)
            let right = BarButtonGroup(buttons: buttonProvider.navigationRightButtons, spacing: 12)
            navigationItem.setLeftBarButton(UIBarButtonItem(customView: left), animated: animated)
            navigationItem.setRightBarButton(UIBarButtonItem(customView: right), animated: animated)
            setToolbarItems(nil, animated: animated)
            navigationController?.setToolbarHidden(true, animated: animated)
        } else if traitCollection.horizontalSizeClass == .compact {
            navigationItem.setLeftBarButton(nil, animated: animated)
            navigationItem.setRightBarButton(nil, animated: animated)
            setToolbarItems([UIBarButtonItem(customView: BarButtonGroup(buttons: buttonProvider.toolbarButtons))], animated: animated)
            navigationController?.setToolbarHidden(false, animated: animated)
        } else {
            navigationItem.setLeftBarButton(nil, animated: animated)
            navigationItem.setRightBarButton(nil, animated: animated)
            setToolbarItems(nil, animated: animated)
            navigationController?.setToolbarHidden(true, animated: animated)
        }
    }
    
    fileprivate func configureSidebarViewController() {
        addChild(sidebarController)
        sidebarController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sidebarController.view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: sidebarController.view.topAnchor),
            view.leftAnchor.constraint(equalTo: sidebarController.view.leftAnchor),
            view.bottomAnchor.constraint(equalTo: sidebarController.view.bottomAnchor),
            view.rightAnchor.constraint(equalTo: sidebarController.view.rightAnchor),
        ])
        sidebarController.didMove(toParent: self)
    }
    
    private func configureSearchController() {
        searchController.delegate = self
        searchController.searchBar.autocorrectionType = .no
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.searchBarStyle = .minimal
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchResultsUpdater = searchResultsController
        searchController.automaticallyShowsCancelButton = false
        searchController.showsSearchResultsController = true
        definesPresentationContext = true
        navigationItem.titleView = searchController.searchBar
    }
    
    // MARK: - UISearchControllerDelegate
    
    func willPresentSearchController(_ searchController: UISearchController) {
        configureBarButtons(searchIsActive: true, animated: true)
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        configureBarButtons(searchIsActive: false, animated: true)
    }
    
    // MARK: - Actions
    
    @objc func chevronLeftButtonTapped() {
        webViewController.webView.goBack()
    }
    
    @objc func chevronRightButtonTapped() {
        webViewController.webView.goForward()
    }
    
    @objc func outlineButtonTapped() {
        let controller = OutlineViewController(webView: webViewController.webView)
        controller.rootView.outlineItemSelected = { [unowned self] item in
            let javascript = "document.querySelectorAll(\"h1, h2, h3, h4, h5, h6\")[\(item.index)].scrollIntoView()"
            self.webViewController.webView.evaluateJavaScript(javascript)
            if #available(iOS 14.0, *),
               let sidebarController = controller.splitViewController as? SidebarController,
               sidebarController.displayMode == .oneOverSecondary {
                sidebarController.hideSidebar()
            } else if let sidebarController = controller.splitViewController as? SidebarController,
                      sidebarController.displayMode == .primaryOverlay {
                sidebarController.hideSidebar()
            } else if #available(iOS 15.0, *),
               let sheetController = controller.sheetPresentationController,
               sheetController.selectedDetentIdentifier != .large {
                return
            } else {
                controller.dismiss(animated: true)
            }
        }
        if #available(iOS 14.0, *), traitCollection.horizontalSizeClass == .regular {
            if sidebarController.displayMode == .secondaryOnly {
                sidebarController.showSidebar(controller)
            } else if !(sidebarController.viewController(for: .primary) is OutlineViewController) {
                sidebarController.setViewController(controller, for: .primary)
            } else {
                sidebarController.hideSidebar()
            }
        } else if traitCollection.horizontalSizeClass == .regular {
            if sidebarController.displayMode == .primaryHidden {
                sidebarController.showSidebar(controller)
            } else if !(sidebarController.viewControllers.first is OutlineViewController) {
                sidebarController.viewControllers[0] = controller
            } else {
                sidebarController.hideSidebar()
            }
        } else {
            let navigationController = UINavigationController(rootViewController: controller)
            if #available(iOS 15.0, *), let sheetController = navigationController.sheetPresentationController {
                sheetController.detents = [.medium(), .large()]
                sheetController.prefersScrollingExpandsWhenScrolledToEdge = false
            }
            present(navigationController, animated: true)
        }
    }
    
    @objc func bookmarkButtonTapped() {
        let bookmarksController = BookmarksViewController()
        bookmarksController.bookmarkTapped = { [weak self] url in self?.openURL(url) }
        if #available(iOS 14.0, *), traitCollection.horizontalSizeClass == .regular {
            if sidebarController.displayMode == .secondaryOnly {
                sidebarController.showSidebar(bookmarksController)
            } else if !(sidebarController.viewController(for: .primary) is BookmarksViewController) {
                sidebarController.setViewController(bookmarksController, for: .primary)
            } else {
                sidebarController.hideSidebar()
            }
        } else if traitCollection.horizontalSizeClass == .regular {
            if sidebarController.displayMode == .primaryHidden {
                sidebarController.showSidebar(bookmarksController)
            } else if !(sidebarController.viewControllers.first is BookmarksViewController) {
                sidebarController.viewControllers[0] = bookmarksController
            } else {
                sidebarController.hideSidebar()
            }
        } else {
            let navigationController = UINavigationController(rootViewController: bookmarksController)
            present(navigationController, animated: true)
        }
    }
    
    @objc func bookmarkButtonLongPressed(sender: Any) {
        func presentBookmarkHUDController(isBookmarked: Bool) {
            let controller = HUDController()
            controller.modalPresentationStyle = .custom
            controller.transitioningDelegate = controller
            controller.direction = isBookmarked ? .down : .up
            controller.imageView.image = isBookmarked ? #imageLiteral(resourceName: "StarAdd") : #imageLiteral(resourceName: "StarRemove")
            controller.label.text = isBookmarked ?
                NSLocalizedString("Added", comment: "Bookmark HUD") :
                NSLocalizedString("Removed", comment: "Bookmark HUD")
            
            present(controller, animated: true, completion: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    controller.dismiss(animated: true, completion: nil)
                })
            })
        }
        
        guard let recognizer = sender as? UILongPressGestureRecognizer,
              recognizer.state == .began,
              let url = webViewController.webView.url else { return }
        let bookmarkService = BookmarkService()
        if let bookmark = bookmarkService.get(url: url) {
            bookmarkService.delete(bookmark)
            presentBookmarkHUDController(isBookmarked: false)
        } else {
            bookmarkService.create(url: url)
            presentBookmarkHUDController(isBookmarked: true)
        }
    }
    
    @objc func diceButtonTapped() {
        if let url = webViewController.webView.url, let zimFileID = url.host {
            openRandomPage(zimFileID: zimFileID)
        } else {
            openRandomPage()
        }
    }
    
    @objc func houseButtonTapped() {
        if let url = webViewController.webView.url, let zimFileID = url.host {
            openMainPage(zimFileID: zimFileID)
        } else if let zimFileID = onDeviceZimFiles?.first?.fileID {
            openMainPage(zimFileID: zimFileID)
        }
    }
    
    @objc func libraryButtonTapped() {
        present(LibraryViewController(), animated: true)
    }
    
    @objc func settingsButtonTapped() {
        present(SettingsViewController(), animated: true)
    }
    
    @objc func moreButtonTapped() {
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        controller.addAction(UIAlertAction(title: "Open Main Page", style: .default, handler: { _  in self.houseButtonTapped()}))
        controller.addAction(UIAlertAction(title: "Open Library", style: .default, handler: { _  in self.libraryButtonTapped()}))
        controller.addAction(UIAlertAction(title: "Open Settings", style: .default, handler: { _  in self.settingsButtonTapped()}))
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(controller, animated: true)
    }
    
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
