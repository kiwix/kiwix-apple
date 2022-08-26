//
//  iOSApp.swift
//  Kiwix for iOS
//
//  Created by Chris Li on 5/21/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import BackgroundTasks
import Combine
import UIKit
import SwiftUI

@main
struct Kiwix: App {
    init() {
        self.registerBackgroundRefreshTask()
        LibraryViewModel.reopen()
        Settings.applyFileBackupSetting()
        Settings.applyLibraryAutoRefreshSetting()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .ignoresSafeArea(.container)
                .environment(\.managedObjectContext, Database.shared.container.viewContext)
        }
    }
    
    private func registerBackgroundRefreshTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: LibraryViewModel.backgroundTaskIdentifier, using: nil
        ) { backgroundTask in
            let task = Task {
                do {
                    try await LibraryViewModel().refresh(isUserInitiated: false)
                    backgroundTask.setTaskCompleted(success: true)
                } catch is CancellationError {
                    backgroundTask.setTaskCompleted(success: true)
                } catch {
                    backgroundTask.setTaskCompleted(success: false)
                }
            }
            backgroundTask.expirationHandler = task.cancel
        }
    }
}

private struct RootView: UIViewControllerRepresentable {
    @State private var isSearchActive = false
    @State private var searchText = ""
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let controller = UIHostingController(rootView: Reader(isSearchActive: $isSearchActive))
        let navigationController = UINavigationController(rootViewController: controller)
        controller.definesPresentationContext = true
        
        // configure search
        context.coordinator.searchController.delegate = context.coordinator
        context.coordinator.searchController.searchBar.autocorrectionType = .no
        context.coordinator.searchController.searchBar.autocapitalizationType = .none
        context.coordinator.searchController.searchBar.searchBarStyle = .minimal
        context.coordinator.searchController.hidesNavigationBarDuringPresentation = false
        context.coordinator.searchController.searchResultsUpdater = context.coordinator
        context.coordinator.searchController.automaticallyShowsCancelButton = false
        context.coordinator.searchController.showsSearchResultsController = true
        context.coordinator.searchController.obscuresBackgroundDuringPresentation = true
        
        // configure navigation item
        controller.navigationItem.titleView = context.coordinator.searchController.searchBar
        if #available(iOS 15.0, *) {
            controller.navigationItem.scrollEdgeAppearance = {
                let apperance = UINavigationBarAppearance()
                apperance.configureWithDefaultBackground()
                return apperance
            }()
            navigationController.toolbar.scrollEdgeAppearance = {
                let apperance = UIToolbarAppearance()
                apperance.configureWithDefaultBackground()
                return apperance
            }()
        }
        
        // observe bookmark toggle notification
        context.coordinator.bookmarkToggleObserver = NotificationCenter.default.addObserver(
            forName: ReaderViewModel.bookmarkNotificationName, object: nil, queue: nil) { notification in
            let isBookmarked = notification.object != nil
            let hudController = HUDController()
            hudController.modalPresentationStyle = .custom
            hudController.transitioningDelegate = hudController
            hudController.direction = isBookmarked ? .down : .up
            hudController.imageView.image = isBookmarked ? #imageLiteral(resourceName: "StarAdd") : #imageLiteral(resourceName: "StarRemove")
            hudController.label.text = isBookmarked ?
                NSLocalizedString("Added", comment: "Bookmark HUD") :
                NSLocalizedString("Removed", comment: "Bookmark HUD")
            controller.present(hudController, animated: true) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    hudController.dismiss(animated: true, completion: nil)
                }
            }
        }
        
        return navigationController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        if !isSearchActive {
            DispatchQueue.main.async {
                context.coordinator.searchController.isActive = false
            }
        }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, UISearchControllerDelegate, UISearchResultsUpdating {
        let rootView: RootView
        let searchController: UISearchController
        var bookmarkToggleObserver: NSObjectProtocol?
        
        init(_ rootView: RootView) {
            self.rootView = rootView
            let searchResultsController = UIHostingController(rootView: Search(searchText: rootView.$searchText))
            self.searchController = UISearchController(searchResultsController: searchResultsController)
            super.init()
        }
        
        func willPresentSearchController(_ searchController: UISearchController) {
            withAnimation {
                rootView.isSearchActive = true
            }
        }
        
        func updateSearchResults(for searchController: UISearchController) {
            guard rootView.isSearchActive else { return }
            rootView.searchText = searchController.searchBar.text ?? ""
        }
    }
}
