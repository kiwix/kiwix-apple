//
//  LibraryViewController.swift
//  Kiwix
//
//  Created by Chris Li on 4/10/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI
import UIKit
import Defaults
import RealmSwift

class LibraryViewController: UISplitViewController, UISplitViewControllerDelegate,
                             UISearchResultsUpdating, UIDocumentPickerDelegate {
    private let primaryController = UIHostingController(rootView: LibraryPrimaryView())
    private let searchResultsController = UIHostingController(rootView: LibrarySearchResultView())
    private let searchController: UISearchController
    
    init() {
        searchController = UISearchController(searchResultsController: searchResultsController)
        
        super.init(nibName: nil, bundle: nil)
        
        delegate = self
        presentsWithGesture = false
        preferredDisplayMode = .allVisible
        viewControllers = [{
            let controller = UINavigationController(rootViewController: primaryController)
            controller.navigationBar.prefersLargeTitles = true
            return controller
        }()]
        showCategory(.wikipedia)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // configure searchController
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.placeholder = "Search by Name"
        searchController.searchResultsUpdater = self
        
        // configure primaryController
        primaryController.navigationItem.title = "Library"
        primaryController.navigationItem.searchController = searchController
        primaryController.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done, target: self, action: #selector(dismissController)
        )
        primaryController.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                image: UIImage(systemName: "gear"),
                style: .plain,
                target: self,
                action: #selector(showSettings(sender:))
            ),
            UIBarButtonItem(
                image: UIImage(systemName: "plus"),
                style: .plain,
                target: self,
                action: #selector(importFiles(sender:))
            )
        ]
        primaryController.rootView.zimFileSelected = { [unowned self] zimFileID, title in
            self.showZimFile(zimFileID, title)
        }
        primaryController.rootView.categorySelected = { [unowned self] category in self.showCategory(category) }
        
        // configure search result controller action
        searchResultsController.rootView.zimFileSelected = { [unowned self] zimFileID, title in
            self.showZimFile(zimFileID, title)
        }
        
        // refresh library when library is opened, but only when library has been previously refreshed
        if Defaults[.libraryLastRefresh] != nil, Defaults[.libraryAutoRefresh], LibraryService.isOutdated {
            LibraryOperationQueue.shared.addOperation(OPDSRefreshOperation())
        }
    }
    
    // MARK: - Delegates
    
    func splitViewController(_ splitViewController: UISplitViewController,
                             collapseSecondary secondaryViewController: UIViewController,
                             onto primaryViewController: UIViewController) -> Bool {
        true
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let searchText = searchText, searchText == searchController.searchBar.text else { return }
            self.searchResultsController.rootView.viewModel.update(searchText)
        }
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        if ZimFileService.getMetaData(url: url) == nil {
            present(FileImportController(fileURL: url), animated: true)
        } else {
            present(FileImportAlertController(fileName: url.lastPathComponent), animated: true)
        }
    }
    
    // MARK: - Action
    
    @objc private func dismissController() {
        dismiss(animated: true)
    }
    
    @objc private func dismissPresentedController() {
        presentedViewController?.dismiss(animated: true)
    }
    
    @objc private func importFiles(sender: UIBarButtonItem) {
        let controller = UIDocumentPickerViewController(documentTypes: ["org.openzim.zim"], in: .open)
        controller.allowsMultipleSelection = false
        controller.delegate = self
        present(controller, animated: true)
    }
    
    @objc private func showSettings(sender: UIBarButtonItem) {
        let controller = UIHostingController(rootView: LibrarySettingsView())
        controller.title = "Settings"
        controller.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done, target: self, action: #selector(dismissPresentedController)
        )
        let navigation = UINavigationController(rootViewController: controller)
        navigation.modalPresentationStyle = .popover
        navigation.popoverPresentationController?.barButtonItem = sender
        self.present(navigation, animated: true)
    }
    
    private func showZimFile(_ zimFileID: String, _ title: String) {
        let controller = UIHostingController(rootView: ZimFileDetailView(fileID: zimFileID))
        controller.title = title
        controller.navigationItem.largeTitleDisplayMode = .never
        showDetailViewController(UINavigationController(rootViewController: controller), sender: nil)
    }
    
    private func showCategory(_ category: ZimFile.Category) {
        let controller = UIHostingController(rootView: LibraryCategoryView(category: category))
        controller.title = category.description
        controller.navigationItem.largeTitleDisplayMode = .never
        controller.rootView.zimFileTapped = { [weak controller] fileID, title in
            let zimFileController = UIHostingController(rootView: ZimFileDetailView(fileID: fileID))
            zimFileController.title = title
            controller?.navigationController?.pushViewController(zimFileController, animated: true)
        }
        showDetailViewController(UINavigationController(rootViewController: controller), sender: nil)
    }
}
