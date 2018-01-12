//
//  BookmarkController.swift
//  Kiwix
//
//  Created by Chris Li on 11/13/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class BookmarkController: PanelTabController {

    override func viewDidLoad() {
        super.viewDidLoad()
        config()
    }
    
    func config() {
        let label = UILabel()
        label.text = "Bookmark"
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)])
    }

}
