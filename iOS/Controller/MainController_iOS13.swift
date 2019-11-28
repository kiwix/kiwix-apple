//
//  MainController_iOS13.swift
//  iOS
//
//  Created by Chris Li on 11/24/19.
//  Copyright © 2019 Chris Li. All rights reserved.
//

import UIKit
import WebKit

@available(iOS 13.0, *)
extension UIViewController {
    var rootViewController: RootController? {
        return view.window?.rootViewController as? RootController
    }
    
    func setChildController(_ newChild: UIViewController?) {
        for child in children {
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
        
        if let child = newChild {
            child.view.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(child.view)
            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: child.view.topAnchor),
                view.leftAnchor.constraint(equalTo: child.view.leftAnchor),
                view.bottomAnchor.constraint(equalTo: child.view.bottomAnchor),
                view.rightAnchor.constraint(equalTo: child.view.rightAnchor),
            ])
            addChild(child)
            child.didMove(toParent: self)
        }
    }
}

@available(iOS 13.0, *)
class RootController: UIViewController {
    private let compactController = RootCompactController()
    private let splitController = MainSplitController()
    private var webControllers = [WebKitWebController()]
    var currentWebController: WebKitWebController {return webControllers[0]}
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupContent(traitCollection: traitCollection)
    }
    
    override func willTransition(to newCollection: UITraitCollection,
                                 with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        setupContent(traitCollection: newCollection)
    }

    private func setupContent(traitCollection: UITraitCollection) {
        switch traitCollection.horizontalSizeClass {
        case .compact:
            setChildController(compactController)
        case .regular:
            setChildController(splitController)
        default:
            setChildController(nil)
        }
    }
}

class RootCompactController: UITableViewController {
    
}

@available(iOS 13.0, *)
class MainSplitController: UISplitViewController {
    let masterController = SideBarController()
    let detailController = UINavigationController(rootViewController: SplitDetailController())
    var rootController: RootController { return parent as! RootController }
    
    init() {
        super.init(nibName: nil, bundle: nil)
        preferredDisplayMode = .allVisible
        viewControllers = [masterController, detailController]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func overrideTraitCollection(forChild childViewController: UIViewController) -> UITraitCollection? {
        let traitCollection = super.overrideTraitCollection(forChild: childViewController)
        if childViewController == detailController, preferredDisplayMode == .allVisible {
            return UITraitCollection(horizontalSizeClass: .compact)
        }
        return traitCollection
    }
}

@available(iOS 13.0, *)
class SplitDetailController: UIViewController, UISearchControllerDelegate {
    private var contentMode: ContentMode = .empty
    private let searchController: UISearchController
    private let searchResultsController: SearchResultsController
    var rootController: RootController { return (splitViewController as! MainSplitController).rootController }
    
    private lazy var searchCancelButton = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                          target: self,
                                                          action: #selector(cancelSearch))
    
    init() {
        self.searchResultsController = SearchResultsController()
        self.searchController = UISearchController(searchResultsController: self.searchResultsController)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.titleView = searchController.searchBar
        searchController.delegate = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.showsSearchResultsController = true
        searchController.searchResultsUpdater = searchResultsController
        definesPresentationContext = true
        
        navigationController?.isToolbarHidden = false
        toolbarItems = [
            UIBarButtonItem(image: UIImage(systemName: "sidebar.left"), style: .plain, target: self, action: #selector(toggleSideBar)),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        ]
    }
    
    func setContentMode(_ contentMode: ContentMode) {
        guard contentMode != self.contentMode else {return}
        self.contentMode = contentMode
        switch contentMode {
        case .welcome:
            setView(UITableView())
        case .web:
            print(rootController)
            setChildController(rootController.currentWebController)
        case .empty:
            setView(nil)
        }
    }
    
    private func setView(_ subView: UIView?) {
        view.subviews.forEach({ $0.removeFromSuperview() })
        if let subView = subView {
            subView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(subView)
            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: subView.topAnchor),
                view.leftAnchor.constraint(equalTo: subView.leftAnchor),
                view.bottomAnchor.constraint(equalTo: subView.bottomAnchor),
                view.rightAnchor.constraint(equalTo: subView.rightAnchor),
            ])
        }
    }
    
    // MARK: UISearchControllerDelegate
    
    func willPresentSearchController(_ searchController: UISearchController) {
        if UIDevice.current.userInterfaceIdiom == .pad {
            navigationItem.setRightBarButton(searchCancelButton, animated: true)
        }
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        if UIDevice.current.userInterfaceIdiom == .pad {
            navigationItem.setRightBarButton(nil, animated: true)
        }
    }
    
    // MARK: Actions
    
    @objc func cancelSearch() {
        /*
         We have to dismiss the `searchController` first, so that the `isBeingDismissed` property is correct on the
         `searchResultsController`. We rely on `isBeingDismissed` to understand if the search text is cleared because
         of user tapped cancel button or manually cleared the serach field.
         */
        searchController.dismiss(animated: true)
        searchController.isActive = false
    }
    
    @objc func toggleSideBar() {
        UIView.animate(withDuration: 0.2) {
            let current = self.splitViewController?.preferredDisplayMode
            self.splitViewController?.preferredDisplayMode = current == .primaryHidden ? .allVisible : .primaryHidden
        }
    }
    
    // MARK: Type Definition
    
    enum ContentMode {
        case web
        case welcome
        case empty
    }
}
