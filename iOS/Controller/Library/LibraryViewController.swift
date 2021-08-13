//
//  LibraryViewController.swift
//  Kiwix
//
//  Created by Chris Li on 4/10/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI
import UIKit
import RealmSwift

@available(iOS 13.0, *)
class LibraryViewController: UISplitViewController, UISplitViewControllerDelegate {
    private let primaryController = UIHostingController(rootView: LibraryPrimaryView())
    private var zimFilesToken: NotificationToken?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureToken()
        
        presentsWithGesture = false
        
        primaryController.navigationItem.title = "Library"
        primaryController.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done, target: self, action: #selector(dismissController)
        )
        primaryController.rootView.categorySelected = { [unowned self] category in self.showCategory(category) }
    }
    
    private func configureToken() {
        zimFilesToken = (try? Realm())?.objects(ZimFile.self)
            .filter(NSPredicate(format: "stateRaw == %@", ZimFile.State.onDevice.rawValue))
            .observe { [unowned self] changes in
                switch changes {
                case .initial(let zimFiles), .update(let zimFiles, _, _, _):
                    if zimFiles.isEmpty {
                        self.preferredDisplayMode = .secondaryOnly
                        viewControllers = [UIViewController(), {
                            let controller = UITableViewController()
                            controller.navigationItem.leftBarButtonItem = UIBarButtonItem(
                                barButtonSystemItem: .done, target: self, action: #selector(dismissController)
                            )
                            let navigationController = UINavigationController(rootViewController: controller)
                            navigationController.navigationBar.prefersLargeTitles = true
                            return navigationController
                        }()]
                    } else {
                        self.preferredDisplayMode = .allVisible
                        viewControllers = [{
                            let controller = UINavigationController(rootViewController: primaryController)
                            controller.navigationBar.prefersLargeTitles = true
                            return controller
                        }()]
                        showCategory(.wikipedia)
                    }
                default:
                    break
                }
            }
    }
    
    // MARK: - Action
    
    @objc private func dismissController() {
        self.dismiss(animated: true)
    }
    
    private func showCategory(_ category: ZimFile.Category) {
        
    }
}

@available(iOS 14.0, *)
class LibraryViewController_old: UISplitViewController, UISplitViewControllerDelegate, UISearchResultsUpdating {
    private let doneButton = UIBarButtonItem(systemItem: .done)
    private let primaryController = UIHostingController(rootView: LibraryPrimaryView())
    private let searchResultsController = UIHostingController(rootView: LibrarySearchResultView())
    private let searchController: UISearchController
    
    init() {
        searchController = UISearchController(searchResultsController: searchResultsController)
        super.init(nibName: nil, bundle: nil)
        doneButton.primaryAction = UIAction(handler: { [unowned self] _ in self.dismiss(animated: true) })
        
        // primaryController
        primaryController.navigationItem.title = "Library"
        primaryController.navigationItem.largeTitleDisplayMode = .always
        primaryController.navigationItem.searchController = searchController
        primaryController.navigationItem.hidesSearchBarWhenScrolling = false
        primaryController.navigationItem.leftBarButtonItem = doneButton
        primaryController.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(systemItem: .add,
                            primaryAction: UIAction(handler: { [unowned self] _ in self.importFile() })),
            UIBarButtonItem(image: UIImage(systemName: "info.circle"),
                            primaryAction: UIAction(handler: { [unowned self] action in self.showInfo(action) })),
        ]
        
        // searchController
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.placeholder = "Search by Name"
        searchController.searchResultsUpdater = self
        
        // splitViewController
        delegate = self
        preferredDisplayMode = .allVisible
        presentsWithGesture = false
        definesPresentationContext = true
        viewControllers = [{
            let controller = UINavigationController(rootViewController: primaryController)
            controller.navigationBar.prefersLargeTitles = true
            return controller
        }()]
        
        // actions
        searchResultsController.rootView.zimFileSelected = {
            [unowned self] zimFileID, title in self.showZimFile(zimFileID, title)
        }
        primaryController.rootView.zimFileSelected = {
            [unowned self] zimFileID, title in self.showZimFile(zimFileID, title)
        }
        primaryController.rootView.categorySelected = { [unowned self] category in self.showCategory(category) }

        showCategory(.wikipedia)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func splitViewController(_ splitViewController: UISplitViewController,
                             collapseSecondary secondaryViewController: UIViewController,
                             onto primaryViewController: UIViewController) -> Bool {
        true
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let searchText = searchText, searchText == searchController.searchBar.text else { return }
            self.searchResultsController.rootView.update(searchText)
        }
    }
    
    private func importFile() {
        let controller = UIDocumentPickerViewController(documentTypes: ["org.openzim.zim"], in: .open)
        present(controller, animated: true)
    }
    
    private func showInfo(_ action: UIAction) {
        let controller = UIHostingController(rootView: LibraryInfoView())
        controller.title = "Info"
        controller.navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .done,
            primaryAction: UIAction(handler: { [weak controller] _ in controller?.dismiss(animated: true) })
        )
        let navigation = UINavigationController(rootViewController: controller)
        navigation.modalPresentationStyle = .popover
        navigation.popoverPresentationController?.barButtonItem = action.sender as? UIBarButtonItem
        self.present(navigation, animated: true, completion: nil)
    }
    
    private func showZimFile(_ zimFileID: String, _ title: String) {
        let controller = UIHostingController(rootView: ZimFileDetailView(fileID: zimFileID))
        controller.title = title
        controller.navigationItem.largeTitleDisplayMode = .never
        showDetailViewController(UINavigationController(rootViewController: controller), sender: nil)
    }
    
    private func showCategory(_ category: ZimFile.Category) {
        let languageFilterButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "globe"),
            primaryAction: UIAction(handler: { action in
                let controller = UIHostingController(rootView: LibraryLanguageFilterView())
                controller.navigationItem.leftBarButtonItem = UIBarButtonItem(
                    systemItem: .done,
                    primaryAction: UIAction(handler: { [weak controller] _ in controller?.dismiss(animated: true) })
                )
                let navigation = UINavigationController(rootViewController: controller)
                navigation.modalPresentationStyle = .popover
                navigation.popoverPresentationController?.barButtonItem = action.sender as? UIBarButtonItem
                self.present(navigation, animated: true, completion: nil)
            })
        )
        let controller = UIHostingController(rootView: LibraryCategoryView(category: category))
        controller.title = category.description
        controller.navigationItem.largeTitleDisplayMode = .never
        controller.navigationItem.rightBarButtonItem = languageFilterButtonItem
        controller.rootView.zimFileTapped = { [weak controller] fileID, title in
            let detailController = UIHostingController(rootView: ZimFileDetailView(fileID: fileID))
            detailController.title = title
            controller?.navigationController?.pushViewController(detailController, animated: true)
        }
        showDetailViewController(UINavigationController(rootViewController: controller), sender: nil)
    }
}
