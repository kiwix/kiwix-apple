//
//  TabContainerController.swift
//  iOS
//
//  Created by Chris Li on 1/10/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit

class TabContainerController: UIViewController {
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    let tabs = [TabController()]
    
//    override func loadView() {
//        view = collectionView
//        collectionView.backgroundColor = .white
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        definesPresentationContext = true
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let tab = tabs.first {
            tab.modalPresentationStyle = .currentContext
            present(tab, animated: false, completion: nil)
        }
    }
}
