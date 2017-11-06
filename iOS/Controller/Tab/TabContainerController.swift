//
//  TabContainerController.swift
//  Kiwix
//
//  Created by Chris Li on 11/6/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class TabContainerController: UIViewController {
    private(set) weak var currentTabController: (UIViewController & TabController)?
    private(set) var tabControllers = [UIViewController & TabController]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tabController: UIViewController & TabController = {
            if #available(iOS 11.0, *) {
                return WebKitTabController()
            } else {
                return LegacyTabController()
            }
        }()
        setTab(controller: tabController)
    }
    
    private func setTab(controller: UIViewController & TabController) {
//        controller.delegate = self
        currentTabController = controller
        tabControllers.append(controller)
        
        addChildViewController(controller)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controller.view)
        [view.topAnchor.constraint(equalTo: controller.view.topAnchor),
         view.leftAnchor.constraint(equalTo: controller.view.leftAnchor),
         view.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor),
         view.rightAnchor.constraint(equalTo: controller.view.rightAnchor)].forEach({ $0.isActive = true })
        controller.didMove(toParentViewController: self)
    }
}

protocol TabController {
    var canGoBack: Bool {get}
    var canGoForward: Bool {get}
    weak var delegate: TabLoadingActivity? {get set}
    
    func goBack()
    func goForward()
    func loadMainPage()
    func load(url: URL)
}

protocol TabLoadingActivity: class {
    func loadingFinished()
}
