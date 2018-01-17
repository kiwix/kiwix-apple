//
//  SettingController.swift
//  Kiwix
//
//  Created by Chris Li on 1/17/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit

class SettingNavigationController: UINavigationController {
    init() {
        super.init(rootViewController: SettingController())
        if #available(iOS 11.0, *) {
            navigationBar.prefersLargeTitles = true
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class SettingController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Setting", comment: "Setting title")
    }
}
