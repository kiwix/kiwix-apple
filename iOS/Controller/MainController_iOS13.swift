//
//  MainController_iOS13.swift
//  iOS
//
//  Created by Chris Li on 11/24/19.
//  Copyright © 2019 Chris Li. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
class RootController: UIViewController {
    private let compactController = RootCompactController()
    private let regularController = RootRegularController()
    
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
            makeChildController(compactController)
        case .regular:
            makeChildController(regularController)
        default:
            makeChildController(nil)
        }
    }
    
    private func makeChildController(_ newChild: UIViewController?) {
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

class RootCompactController: UIViewController {
    
}

class RootRegularController: UISplitViewController, UISplitViewControllerDelegate {
    init() {
        super.init(nibName: nil, bundle: nil)

        preferredDisplayMode = .allVisible
        delegate = self
        
        let master = UIViewController()
        let detail = UIViewController()
        viewControllers = [
            UITableViewController(),
            UINavigationController(rootViewController: detail)]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
