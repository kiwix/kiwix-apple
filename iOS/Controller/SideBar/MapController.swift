//
//  MapController.swift
//  iOS
//
//  Created by Chris Li on 11/30/19.
//  Copyright © 2019 Chris Li. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
class MapController: UIViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
        tabBarItem = UITabBarItem(title: "Map",
                                  image: UIImage(systemName: "map"),
                                  selectedImage: UIImage(systemName: "map.fill"))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Map"
        navigationController?.navigationBar.prefersLargeTitles = true
    }
}
