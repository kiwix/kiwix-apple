//
//  TabContainerController.swift
//  Kiwix
//
//  Created by Chris Li on 11/6/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class TabContainerController: UIViewController, TabControllerDelegate {
    weak var delegate: TabContainerControllerDelegate?
    private(set) weak var currentTabController: (UIViewController & TabController)?
    private var tabControllers = [UIViewController & TabController]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.orange.withAlphaComponent(0.3)
    }
    
    func switchToNewTab() {
        var tabController: UIViewController & TabController = {
            if #available(iOS 11.0, *) {
                return WebKitTabController()
            } else {
                return LegacyTabController()
            }
        }()
        tabController.delegate = self
        setTab(controller: tabController)
    }
    
    private func setTab(controller: UIViewController & TabController) {
        currentTabController = controller
        tabControllers.append(controller)
        
        addChildViewController(controller)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controller.view)
        NSLayoutConstraint.activate([view.topAnchor.constraint(equalTo: controller.view.topAnchor),
                                     view.leftAnchor.constraint(equalTo: controller.view.leftAnchor),
                                     view.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor),
                                     view.rightAnchor.constraint(equalTo: controller.view.rightAnchor)])
        controller.didMove(toParentViewController: self)
        
        delegate?.tabDidBecameCurrent(controller: controller)
    }
    
    // MARK: - TabControllerDelegate
    
    func webViewDidFinishLoad(controller: UIViewController & TabController) {
        delegate?.tabDidFinishLoading(controller: controller)
    }
}

protocol TabContainerControllerDelegate: class {
    func tabDidBecameCurrent(controller: UIViewController & TabController)
    func tabDidFinishLoading(controller: UIViewController & TabController)
}

protocol TabController {
    var canGoBack: Bool {get}
    var canGoForward: Bool {get}
    weak var delegate: TabControllerDelegate? {get set}
    
    func goBack()
    func goForward()
    func loadMainPage(id: ZimFileID)
    func load(url: URL)
}

protocol TabControllerDelegate: class {
    func webViewDidFinishLoad(controller: UIViewController & TabController)
}
