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
class LibraryViewController: UISplitViewController {
    let sidebarController = UIViewController()
    
    let doneButton = UIBarButtonItem(systemItem: .done)
    
    init() {
        super.init(style: .doubleColumn)
        preferredDisplayMode = .oneBesideSecondary
        preferredSplitBehavior = .tile
        presentsWithGesture = false
        
        doneButton.primaryAction = UIAction(handler: { [unowned self] _ in self.dismiss(animated: true) })
        
        sidebarController.navigationItem.title = "Library"
        sidebarController.navigationItem.largeTitleDisplayMode = .always
        sidebarController.navigationItem.leftBarButtonItem = doneButton
        let sidebarNavigationController = UINavigationController(rootViewController: sidebarController)
        sidebarNavigationController.navigationBar.prefersLargeTitles = true
        setViewController(sidebarNavigationController, for: .primary)
        
        let controller = UIHostingController(rootView: LibraryCategoryView(category: .wikipedia))
        setViewController(controller, for: .secondary)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
