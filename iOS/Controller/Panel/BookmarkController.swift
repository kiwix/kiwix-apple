//
//  BookmarkController.swift
//  Kiwix
//
//  Created by Chris Li on 11/13/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class BookmarkController: PanelTabController {
    let tableView = UITableView()
    let emptyBackgroundView = BackgroundStackView(
        image: #imageLiteral(resourceName: "StarColor"),
        title: NSLocalizedString("Bookmark your favorite articles", comment: "Help message when there's no bookmark to show"),
        subtitle: NSLocalizedString("To add, long press the star button on the tool bar.", comment: "Help message when there's no bookmark to show")
    )

    override func viewDidLoad() {
        super.viewDidLoad()
//        tableView.delegate = self
//        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        configure(stackView: emptyBackgroundView)
    }
}
