//
//  FavoriteController.swift
//  iOS
//
//  Created by Chris Li on 11/30/19.
//  Copyright © 2019 Chris Li. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
class FavoriteController: UITableViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
        title = "Favorite"
        tabBarItem = UITabBarItem(title: "Favorite",
                                  image: UIImage(systemName: "star"),
                                  selectedImage: UIImage(systemName: "star.fill"))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
    }
}
