//
//  BookmarkCollectionController.swift
//  Kiwix
//
//  Created by Chris Li on 1/12/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class BookmarkCollectionController: UIViewController {

    @IBOutlet weak var colectionView: UICollectionView!
    
    var book: Book? {
        didSet {
            if let book = book {
                title = book.title
            } else {
                title = "All"
            }
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

}
