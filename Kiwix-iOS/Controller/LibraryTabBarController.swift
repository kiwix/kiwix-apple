//
//  LibraryTabBarController.swift
//  Kiwix
//
//  Created by Chris Li on 2/11/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class LibraryTabBarController: UITabBarController {
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        tabBar.frame = CGRectMake(tabBar.frame.origin.x, tabBar.frame.origin.y, 0, 0)
    }
}
