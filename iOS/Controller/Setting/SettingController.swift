//
//  SettingController.swift
//  Kiwix
//
//  Created by Chris Li on 1/17/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit

class SettingNavigationController: UINavigationController {
    convenience init() {
        self.init(rootViewController: SettingController())
        modalPresentationStyle = .formSheet
        if #available(iOS 11.0, *) {
            navigationBar.prefersLargeTitles = true
        }
    }
}

class SettingController: PresentationBaseController {
    let tableView = UITableView(frame: .zero, style: .grouped)
    override func loadView() {
        view = tableView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Setting", comment: "Setting title")
    }
}
