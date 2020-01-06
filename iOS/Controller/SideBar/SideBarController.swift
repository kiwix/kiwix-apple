//
//  SideBarController.swift
//  iOS
//
//  Created by Chris Li on 11/27/19.
//  Copyright © 2019 Chris Li. All rights reserved.
//

import UIKit

class SideBarController: UITabBarController {
    let favoriteController = BookmarkController()
    let outlineController = OutlineController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewControllers = [
            UINavigationController(rootViewController: favoriteController),
            UINavigationController(rootViewController: outlineController),
        ]
    }
}
