//
//  BookmarkViewController.swift
//  iOS
//
//  Created by Chris Li on 1/24/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit

class BookmarkViewController: BaseController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Bookmark", comment: "Bookmark view title")
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
        }
    }
    
}
