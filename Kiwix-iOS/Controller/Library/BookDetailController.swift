//
//  BookDetailController.swift
//  Kiwix
//
//  Created by Chris Li on 8/17/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class BookDetailController: UITableViewController {
    
    @IBOutlet weak var favIconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var hasPicIndicator: UILabel!
    @IBOutlet weak var hasPicLabel: UILabel!
    @IBOutlet weak var hasIndexIndicator: UILabel!
    @IBOutlet weak var hasIndexLabel: UILabel!
    
    var book: Book?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hasPicIndicator.layer.cornerRadius = 2.0
        hasIndexIndicator.layer.cornerRadius = 2.0
        hasPicIndicator.layer.masksToBounds = true
        hasIndexIndicator.layer.masksToBounds = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        configureViews()
    }
    
    func configureViews() {
        guard let book = book else {return}
        
        favIconImageView.image = UIImage(data: book.favIcon ?? NSData())
        titleLabel.text = book.title
        
        hasPicIndicator.backgroundColor = book.hasPic ? AppColors.hasPicTintColor : UIColor.lightGrayColor()
        hasPicLabel.text = book.hasPic ? LocalizedStrings.BookDetail.hasPic : LocalizedStrings.BookDetail.noPic
        hasIndexIndicator.backgroundColor = book.hasIndex ? AppColors.hasIndexTintColor : UIColor.lightGrayColor()
        hasIndexLabel.text = book.hasPic ? LocalizedStrings.BookDetail.hasIndex : LocalizedStrings.BookDetail.noIndex
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }

}

extension LocalizedStrings {
    class BookDetail {
        private static let comment = "Library, Book Detail"
        static let hasIndex = NSLocalizedString("Index", comment: comment)
        static let hasPic = NSLocalizedString("Pictures", comment: comment)
        static let noIndex = NSLocalizedString("No Index", comment: comment)
        static let noPic = NSLocalizedString("No Picture", comment: comment)
    }
}
