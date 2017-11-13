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
    private(set) var isDisplayingHome = true
    
    private lazy var home = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Home") as! HomeController
    private weak var currentTab: (UIViewController & TabController)?
    private var tabs = Set<UIViewController>()
    
    func switchToHome() {
        isDisplayingHome = true
        setChildController(controller: home)
    }
    
    func switchToNewTab() {
        let tab: UIViewController & TabController = {
            if #available(iOS 11.0, *) {
                return WebKitTabController()
            } else {
                return LegacyTabController()
            }
        }()
        switchTo(tab: tab)
    }
    
    func switchToCurrentTab() {
        if let tab = currentTab {
            switchTo(tab: tab)
        } else {
            switchToNewTab()
        }
    }
    
    private func switchTo(tab: UIViewController & TabController) {
        isDisplayingHome = false
        currentTab = tab
        currentTab?.delegate = self
        tabs.insert(tab)
        setChildController(controller: tab)
    }
    
    private func setChildController(controller: UIViewController) {
        childViewControllers.forEach { $0.removeFromParentViewController() }
        view.subviews.forEach({ $0.removeFromSuperview() })
        
        addChildViewController(controller)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controller.view)
        NSLayoutConstraint.activate([view.topAnchor.constraint(equalTo: controller.view.topAnchor),
                                     view.leftAnchor.constraint(equalTo: controller.view.leftAnchor),
                                     view.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor),
                                     view.rightAnchor.constraint(equalTo: controller.view.rightAnchor)])
        controller.didMove(toParentViewController: self)
        if let tabController = controller as? UIViewController & TabController {
            delegate?.tabWillBecomeCurrent(controller: tabController)
        } else if let _ = controller as? HomeController {
            delegate?.homeWillBecomeCurrent()
        }
    }
    
    func go(_ direction: TabNavigationDirection, in tab: TabType) {
        
    }
    
    func load(url: URL, in tab: TabType, animated: Bool = true) {
        if currentTab == nil {
            switchToNewTab()
        }
        currentTab?.load(url: url)
    }
    
    func loadMain(id: ZimFileID,  in tab: TabType, animated: Bool = true) {
        if currentTab == nil {
            switchToNewTab()
        }
        currentTab?.loadMainPage(id: id)
    }
    
//    func loadInNewTab(url: URL, animated: Bool) {
//        switchToNewTab()
//        loadInCurrentTab(url: url, animated: true)
//    }
    
    enum TabType {
        case new, current, index(Int)
    }
    
    enum TabNavigationDirection {
        case back, forward
    }
    
    // MARK: - TabControllerDelegate
    
    func webViewDidFinishLoad(controller: UIViewController & TabController) {
        delegate?.tabDidFinishLoading(controller: controller)
    }
}

protocol TabContainerControllerDelegate: class {
    func homeWillBecomeCurrent()
    func tabWillBecomeCurrent(controller: UIViewController & TabController)
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
