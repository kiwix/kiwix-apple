//
//  SidebarController.swift
//  Kiwix
//
//  Created by Chris Li on 12/25/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import UIKit
import Defaults

class SidebarController: UISplitViewController {
    init() {
        if #available(iOS 14.0, *) {
            super.init(style: .doubleColumn)
        } else {
            super.init(nibName: nil, bundle: nil)
            viewControllers = [UIViewController(), UIViewController()]
            preferredDisplayMode = .primaryHidden
        }
        presentsWithGesture = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
}
