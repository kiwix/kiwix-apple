//
//  TabContainerController.swift
//  Kiwix
//
//  Created by Chris Li on 11/6/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class TabsController: UIViewController, TabControllerDelegate {
    weak var delegate: TabContainerControllerDelegate?
    private(set) var isDisplayingHome = true
    
    private let home = UIStoryboard(name: "Tab", bundle: nil).instantiateViewController(withIdentifier: "Home") as! HomeController
    private(set) weak var current: (UIViewController & WebViewController)?
    private var tabs = Set<UIViewController>()
    
    enum TabType {
        case new, current, index(Int)
        
        static func == (lhs: TabType, rhs: TabType) -> Bool {
            switch (lhs, rhs) {
            case (.new, .new):
                return true
            case (.current, .current):
                return true
            case let (.index(lhsIndex), .index(rhsIndex)):
                return lhsIndex == rhsIndex
            default:
                return false
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Tab Management
    
    func switchToHome() {
        isDisplayingHome = true
        setChildController(controller: home)
        home.libraryButton.addTarget(self, action: #selector(libraryButtonTapped), for: .touchUpInside)
        home.settingsButton.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)
    }
    
    func switchToNewTab() {
        let tab: UIViewController & WebViewController = {
            if #available(iOS 11.0, *) {
                return WebKitTabController()
            } else {
                return LegacyTabController()
            }
        }()
        switchTo(tab: tab)
    }
    
    func switchToCurrentTab() {
        if let tab = current {
            switchTo(tab: tab)
        } else {
            switchToNewTab()
        }
    }
    
    private func switchTo(tab: UIViewController & WebViewController) {
        isDisplayingHome = false
        current = tab
        current?.delegate = self
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
        if let tabController = controller as? UIViewController & WebViewController {
            delegate?.tabWillBecomeCurrent(controller: tabController)
        } else if let _ = controller as? HomeController {
            delegate?.homeWillBecomeCurrent()
        }
    }
    
    // MARK: - Loading
    
    func load(url: URL, in tab: TabType, animated: Bool = true) {
        if current == nil {
            switchToNewTab()
        }
        current?.load(url: url)
    }
    
    func loadMain(id: ZimFileID,  in tab: TabType, animated: Bool = true) {
        if current == nil {
            switchToNewTab()
        }
        current?.loadMainPage(id: id)
    }
    
//    func loadInNewTab(url: URL, animated: Bool) {
//        switchToNewTab()
//        loadInCurrentTab(url: url, animated: true)
//    }
    
    // MARK: - Button Actions
    
    @objc func libraryButtonTapped() {
        delegate?.libraryButtonTapped()
    }
    
    @objc func settingsButtonTapped() {
        delegate?.settingsButtonTapped()
    }
    
    // MARK: - TabControllerDelegate
    
    func webViewDidFinishLoad(controller: UIViewController & WebViewController) {
        delegate?.tabDidFinishLoading(controller: controller)
    }
}

// MARK: - Protocols

protocol TabContainerControllerDelegate: class {
    func homeWillBecomeCurrent()
    func tabWillBecomeCurrent(controller: UIViewController & WebViewController)
    func tabDidFinishLoading(controller: UIViewController & WebViewController)
    func libraryButtonTapped()
    func settingsButtonTapped()
}

protocol WebViewController {
    var canGoBack: Bool {get}
    var canGoForward: Bool {get}
    weak var delegate: TabControllerDelegate? {get set}
    
    func goBack()
    func goForward()
    func loadMainPage(id: ZimFileID)
    func load(url: URL)
    func getTableOfContent(completion: @escaping (([HTMLHeading]) -> Void))
}

protocol TabControllerDelegate: class {
    func webViewDidFinishLoad(controller: UIViewController & WebViewController)
}
