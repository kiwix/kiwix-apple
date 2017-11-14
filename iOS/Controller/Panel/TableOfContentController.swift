//
//  TableOfContentController.swift
//  Kiwix
//
//  Created by Chris Li on 11/13/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class TableOfContentController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        config()
    }

    func config() {
        let label = UILabel()
        label.text = "Table of Content"
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)])
    }
}
