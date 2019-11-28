//
//  SideBarController.swift
//  iOS
//
//  Created by Chris Li on 11/27/19.
//  Copyright © 2019 Chris Li. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
class SideBarController: UITabBarController {
    init() {
        super.init(nibName: nil, bundle: nil)
        viewControllers = [
            UINavigationController(rootViewController: SessionController()),
            UINavigationController(rootViewController: FavoriteController()),
            UINavigationController(rootViewController: MapController()),
        ]
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@available(iOS 13.0, *)
class SessionController: UITableViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
        tabBarItem = UITabBarItem(title: "Session", image: UIImage(systemName: "desktopcomputer"), tag: 0)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Session"
        navigationController?.navigationBar.prefersLargeTitles = true
    }
}

@available(iOS 13.0, *)
class FavoriteController: UITableViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
        tabBarItem = UITabBarItem(title: "Favorite", image: UIImage(systemName: "star"), tag: 1)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Favorite"
        navigationController?.navigationBar.prefersLargeTitles = true
    }
}

@available(iOS 13.0, *)
class MapController: UIViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
        tabBarItem = UITabBarItem(title: "Map", image: UIImage(systemName: "map"), tag: 2)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Map"
        navigationController?.navigationBar.prefersLargeTitles = true
    }
}
