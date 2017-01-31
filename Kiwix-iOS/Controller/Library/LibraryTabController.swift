//
//  LibraryTabController.swift
//  Kiwix
//
//  Created by Chris Li on 1/25/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import UserNotifications

class LibraryTabController: UITabBarController {
    let cloud = UIStoryboard(name: "Library", bundle: nil).instantiateViewController(withIdentifier: "LibraryBookNavController") as! UINavigationController
    let local = UIStoryboard(name: "Library", bundle: nil).instantiateViewController(withIdentifier: "LibraryBookNavController") as! UINavigationController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (cloud.topViewController as! LibraryBooksController).isCloudTab = true
        (local.topViewController as! LibraryBooksController).isCloudTab = false
    
        viewControllers = [cloud, local]
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _ in }
    }
}
