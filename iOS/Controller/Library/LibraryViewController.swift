//
//  LibraryViewController.swift
//  Kiwix
//
//  Created by Chris Li on 4/10/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI
import UIKit

@available(iOS 14.0, *)
class LibraryViewController: UISplitViewController, UISplitViewControllerDelegate {
    let sidebarController = UIHostingController(rootView: LibrarySidebarView())
    
    let doneButton = UIBarButtonItem(systemItem: .done)
    
    init() {
        super.init(style: .doubleColumn)
        delegate = self
        preferredDisplayMode = .oneBesideSecondary
        preferredSplitBehavior = .tile
        presentsWithGesture = false
        
        doneButton.primaryAction = UIAction(handler: { [unowned self] _ in self.dismiss(animated: true) })
        
        sidebarController.navigationItem.title = "Library"
        sidebarController.navigationItem.largeTitleDisplayMode = .always
        sidebarController.navigationItem.leftBarButtonItem = doneButton
        sidebarController.rootView.categorySelected = { [unowned self] category in self.showCategory(category) }
        let sidebarNavigationController = UINavigationController(rootViewController: sidebarController)
        sidebarNavigationController.navigationBar.prefersLargeTitles = true
        setViewController(sidebarNavigationController, for: .primary)
        
        showCategory(.wikipedia)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showCategory(_ category: ZimFile.Category) {
        let languageFilterButtonItem = UIBarButtonItem(
            title: "Show Language Filter",
            image: UIImage(systemName: "globe"),
            primaryAction: UIAction(handler: { action in
                let controller = UIHostingController(rootView: LibraryLanguageFilterView())
                controller.rootView.doneButtonTapped = { [weak controller] in
                    controller?.dismiss(animated: true)
                }
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
        setViewController(UINavigationController(rootViewController: controller), for: .secondary)
//        if isCollapsed, let navigationController = viewController(for: .primary) as? UINavigationController {
//            navigationController.pushViewController(controller, animated: true)
//        } else {
//            setViewController(UINavigationController(rootViewController: controller), for: .secondary)
//        }
        
    }
//    func splitViewController(_ svc: UISplitViewController, topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column) -> UISplitViewController.Column {
//        .primary
//    }
//
//    func splitViewControllerDidExpand(_ svc: UISplitViewController) {
//        guard let navigationController = svc.viewController(for: .primary) as? UINavigationController,
//              navigationController.viewControllers.count > 1 else { return }
//        let s = UINavigationController()
//        s.viewControllers = Array(navigationController.viewControllers[1...])
//        svc.setViewController(s, for: .secondary)
//        navigationController.viewControllers.removeSubrange(1...)
//    }
}
