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
    private lazy var home = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Home") as! HomeController
    private(set) weak var currentTabController: (UIViewController & TabController)?
    private var tabControllers = Set<UIViewController>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        switchToHome()
    }
    
    func switchToNewTab() {
        let tabController: UIViewController & TabController = {
            if #available(iOS 11.0, *) {
                return WebKitTabController()
            } else {
                return LegacyTabController()
            }
        }()
        setChildController(controller: tabController)
    }
    
    func switchToHome() {
        setChildController(controller: home)
    }
    
    func switchToCurrentTab() {
        if let tab = currentTabController {
            setChildController(controller: tab)
        } else {
            switchToNewTab()
        }
    }
    
    private func setChildController(controller: UIViewController) {
        childViewControllers.forEach { (controller) in
            if var tab = controller as? TabController {
                tab.delegate = nil
            }
            controller.removeFromParentViewController()
        }
        view.subviews.forEach({ $0.removeFromSuperview() })
        
        addChildViewController(controller)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controller.view)
        NSLayoutConstraint.activate([view.topAnchor.constraint(equalTo: controller.view.topAnchor),
                                     view.leftAnchor.constraint(equalTo: controller.view.leftAnchor),
                                     view.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor),
                                     view.rightAnchor.constraint(equalTo: controller.view.rightAnchor)])
        controller.didMove(toParentViewController: self)
        if var tabController = controller as? UIViewController & TabController {
            tabController.delegate = self
            currentTabController = tabController
            tabControllers.insert(tabController)
            delegate?.tabDidBecameCurrent(controller: tabController)
        }
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
