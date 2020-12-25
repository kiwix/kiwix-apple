//
//  SidebarController.swift
//  Kiwix
//
//  Created by Chris Li on 12/25/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import UIKit
import Defaults

class SidebarController: UISplitViewController, UISplitViewControllerDelegate {
    private let contentHostingController = UIViewController()
    
    init() {
        if #available(iOS 14.0, *) {
            super.init(style: .doubleColumn)
        } else {
            super.init(nibName: nil, bundle: nil)
            delegate = self
            preferredDisplayMode = .primaryHidden
            viewControllers = [UIViewController(), contentHostingController]
        }
        presentsWithGesture = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // on iOS 12 & 13, hide sidebar when view transition to horizontally regular from non-regular and when
        // automatic sidebar display mode is used. This is because we have our own heuristic for automatic mode.
        if #available(iOS 14.0, *) { } else {
            if Defaults[.sideBarDisplayMode] == .automatic {
                preferredDisplayMode = .primaryHidden
            }
        }
    }
    
    func showSidebar(_ controller: UIViewController) {
        if #available(iOS 14.0, *) {
            setViewController(controller, for: .primary)
            show(.primary)
            preferredDisplayMode = {
                switch Defaults[.sideBarDisplayMode] {
                case .automatic:
                    return .automatic
                case .overlay:
                    return .oneOverSecondary
                case .sideBySide:
                    return .oneBesideSecondary
                }
            }()
        } else {
            if viewControllers.count == 1 {
                viewControllers.insert(controller, at: 0)
            } else {
                viewControllers[0] = controller
            }
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
                self.preferredDisplayMode = {
                    if #available(iOS 13.0, *) {
                        switch Defaults[.sideBarDisplayMode] {
                        case .automatic:
                            let size = self.view.frame.size
                            return size.width > size.height ? .allVisible : .primaryOverlay
                        case .overlay:
                            return .primaryOverlay
                        case .sideBySide:
                            return .allVisible
                        }
                    } else {
                        return .allVisible
                    }
                }()
            }
        }
    }
    
    func hideSidebar() {
        if #available(iOS 14.0, *) {
            hide(.primary)
            transitionCoordinator?.animate(alongsideTransition: { _ in }, completion: { context in
                guard !context.isCancelled else { return }
                self.setViewController(nil, for: .primary)
            })
        } else {
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn) {
                self.preferredDisplayMode = .primaryHidden
            } completion: { completed in
                guard completed else { return }
                self.viewControllers[0] = UIViewController()
            }
        }
    }
    
    func setContentViewController(_ controller: UIViewController) {
        if #available(iOS 14.0, *) {
            guard viewController(for: .secondary) !== controller else { return }
            setViewController(controller, for: .secondary)
        } else {
            guard !contentHostingController.children.contains(controller) else { return }
            contentHostingController.children.forEach { child in
                child.willMove(toParent: nil)
                child.view.removeFromSuperview()
                child.removeFromParent()
            }
            contentHostingController.addChild(controller)
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            contentHostingController.view.addSubview(controller.view)
            NSLayoutConstraint.activate([
                controller.view.topAnchor.constraint(equalTo: contentHostingController.view.topAnchor),
                controller.view.leftAnchor.constraint(equalTo: contentHostingController.view.leftAnchor),
                controller.view.bottomAnchor.constraint(equalTo: contentHostingController.view.bottomAnchor),
                controller.view.rightAnchor.constraint(equalTo: contentHostingController.view.rightAnchor),
            ])
            controller.didMove(toParent: self)
        }
    }
    
    // MARK: - UISplitViewControllerDelegate
    
    // only needed for iOS 12 & 13
    func primaryViewController(forCollapsing splitViewController: UISplitViewController) -> UIViewController? {
        splitViewController.viewControllers.last
    }
    
    // only needed for iOS 12 & 13
    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        splitViewController.viewControllers.last
    }
}
